$ErrorActionPreference = 'Stop'
$baseUrl = 'http://localhost:3000/api/v1'
$envFile = Join-Path $PSScriptRoot '..\.env'
$script:passed = 0
$script:failed = 0

function Read-EnvFile {
    $values = @{}
    if (Test-Path $envFile) {
        foreach ($line in Get-Content $envFile) {
            if ($line -match '^\s*([^#=]+)=(.*)$') {
                $values[$Matches[1].Trim()] = $Matches[2].Trim()
            }
        }
    }
    return $values
}

function Invoke-Api {
    param($Method, $Path, $Body = $null, $Token = $null)
    $headers = @{}
    if ($Token) { $headers['Authorization'] = "Bearer $Token" }
    $params = @{ Method = $Method; Uri = "$baseUrl$Path"; Headers = $headers; TimeoutSec = 30 }
    if ($Body) {
        $params['Body'] = ($Body | ConvertTo-Json -Depth 10)
        $params['ContentType'] = 'application/json'
    }
    try {
        return @{ ok = $true; response = Invoke-RestMethod @params }
    } catch {
        $detail = $null
        if ($_.ErrorDetails.Message) { $detail = $_.ErrorDetails.Message | ConvertFrom-Json }
        return @{ ok = $false; error = $detail; raw = $_.Exception.Message }
    }
}

function Assert-Step {
    param($Name, $Condition, $Detail = '')
    if ($Condition) {
        $script:passed++
        Write-Host "[OK]    $Name" -ForegroundColor Green
    } else {
        $script:failed++
        Write-Host "[FALLO] $Name  $Detail" -ForegroundColor Red
    }
}

Write-Host "`n=== Ayni Ruta: smoke tests por consola ($baseUrl) ===`n"

$health = Invoke-Api GET '/health'
Assert-Step 'Health check responde ok' ($health.ok -and $health.response.data.status -eq 'ok') $health.raw

$noToken = Invoke-Api GET '/users/me'
Assert-Step 'Guard rechaza requests sin token (MISSING_TOKEN)' ($noToken.error.error.code -eq 'MISSING_TOKEN') $noToken.raw

$badBody = Invoke-Api POST '/routing/recommendations' @{ origin = 'no-soy-coordenada' }
Assert-Step 'Rutas sin token tambien rechazadas' ($badBody.error.error.code -eq 'MISSING_TOKEN') $badBody.raw

$envValues = Read-EnvFile
$supabaseUrl = $envValues['SUPABASE_URL']
$serviceKey = $envValues['SUPABASE_SERVICE_ROLE_KEY']

if (-not $supabaseUrl -or -not $serviceKey) {
    Write-Host "`nSupabase no esta configurado en .env: se omiten las pruebas autenticadas." -ForegroundColor Yellow
    Write-Host "Llena SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY y SUPABASE_JWT_SECRET, corre los seeds y vuelve a ejecutar este script.`n"
    Write-Host "Resultado: $script:passed OK, $script:failed fallos"
    exit ([int]($script:failed -gt 0))
}

$testEmail = 'smoke.ayni@test.com'
$testPassword = 'AyniRuta2026!'
$supabaseHeaders = @{ apikey = $serviceKey; Authorization = "Bearer $serviceKey" }

try {
    Invoke-RestMethod -Method POST -Uri "$supabaseUrl/auth/v1/admin/users" -Headers $supabaseHeaders -ContentType 'application/json' -Body (@{ email = $testEmail; password = $testPassword; email_confirm = $true } | ConvertTo-Json) | Out-Null
} catch {}

$session = Invoke-RestMethod -Method POST -Uri "$supabaseUrl/auth/v1/token?grant_type=password" -Headers @{ apikey = $serviceKey } -ContentType 'application/json' -Body (@{ email = $testEmail; password = $testPassword } | ConvertTo-Json)
$token = $session.access_token
Assert-Step 'Login del usuario de prueba en Supabase' ($null -ne $token)

$bootstrap = Invoke-Api POST '/users/me/bootstrap' @{ displayName = 'Usuario Smoke' } $token
Assert-Step 'Bootstrap del perfil' ($bootstrap.ok -and $bootstrap.response.data.id) ($bootstrap.error.error.message)

$me = Invoke-Api GET '/users/me' $null $token
Assert-Step 'GET /users/me devuelve el perfil' ($me.ok -and $me.response.data.ayniPoints -ge 0) ($me.error.error.message)

$patch = Invoke-Api PATCH '/users/me' @{ defaultPriority = 'cost' } $token
Assert-Step 'PATCH /users/me actualiza preferencias' ($patch.ok -and $patch.response.data.defaultPriority -eq 'cost') ($patch.error.error.message)

$lines = Invoke-Api GET '/transports/lines' $null $token
$hasLines = $lines.ok -and $lines.response.data.Count -gt 0
Assert-Step 'Catalogo de lineas (requiere seeds)' $hasLines ($lines.error.error.message)

if ($hasLines) {
    $cableLine = $lines.response.data | Where-Object { $_.kind -eq 'cable_car' } | Select-Object -First 1
    $stops = Invoke-Api GET "/transports/lines/$($cableLine.id)/stops" $null $token
    Assert-Step "Estaciones de $($cableLine.name)" ($stops.ok -and $stops.response.data.Count -ge 2) ($stops.error.error.message)
    $firstStop = $stops.response.data[0]
}

$recommendation = Invoke-Api POST '/routing/recommendations' @{ origin = @{ lat = -16.4957; lng = -68.1335 }; destination = @{ lat = -16.5473; lng = -68.0885 }; priority = 'time' } $token
$hasOptions = $recommendation.ok -and $recommendation.response.data.options.Count -gt 0
Assert-Step 'Motor de rutas: Plaza Murillo -> Irpavi' $hasOptions ($recommendation.error.error.message)
if ($hasOptions) {
    $bestOption = $recommendation.response.data.options[0]
    Write-Host ("        mejor opcion: {0} min, Bs {1}, {2} tramos" -f $bestOption.totalDurationMinutes, $bestOption.totalCostBs, $bestOption.legs.Count)
}

$incident = Invoke-Api POST '/incidents' @{ kind = 'blockade'; position = @{ lat = -16.5100; lng = -68.1300 }; description = 'Bloqueo de prueba smoke test' } $token
Assert-Step 'Reportar incidente' ($incident.ok -and $incident.response.data.id) ($incident.error.error.message)

$active = Invoke-Api GET '/incidents/active' $null $token
Assert-Step 'Incidentes activos' $active.ok ($active.error.error.message)

$pending = Invoke-Api GET '/incidents/pending/near?lat=-16.5100&lng=-68.1300' $null $token
Assert-Step 'Incidentes pendientes cercanos' $pending.ok ($pending.error.error.message)

$trip = Invoke-Api POST '/trips' @{ routeSnapshot = @{ demo = $true } } $token
$tripOk = $trip.ok -and $trip.response.data.id
Assert-Step 'Iniciar viaje' $tripOk ($trip.error.error.message)

if ($tripOk -and $hasLines) {
    $share = Invoke-Api POST '/collaboration/shares' @{ tripId = $trip.response.data.id; lineId = $cableLine.id } $token
    $shareOk = $share.ok -and $share.response.data.id
    Assert-Step 'Compartir ubicacion (share)' $shareOk ($share.error.error.message)
    if ($shareOk) {
        $ping = Invoke-Api POST "/collaboration/shares/$($share.response.data.id)/pings" @{ lat = $firstStop.lat; lng = $firstStop.lng } $token
        Assert-Step 'Registrar ping de ubicacion' $ping.ok ($ping.error.error.message)
        $query = Invoke-Api POST '/collaboration/vehicle-queries' @{ lineId = $cableLine.id; stopId = $firstStop.id } $token
        Assert-Step 'Consultar donde viene el transporte' ($query.ok -and $null -ne $query.response.data.available) ($query.error.error.message)
        $stop = Invoke-Api PATCH "/collaboration/shares/$($share.response.data.id)/stop" $null $token
        Assert-Step 'Detener share y acreditar puntos' $stop.ok ($stop.error.error.message)
    }
    $finish = Invoke-Api PATCH "/trips/$($trip.response.data.id)/finish" $null $token
    Assert-Step 'Finalizar viaje' $finish.ok ($finish.error.error.message)
}

$ayni = Invoke-Api GET '/users/me/ayni' $null $token
Assert-Step 'Saldo e historial Ayni' ($ayni.ok -and $null -ne $ayni.response.data.balance) ($ayni.error.error.message)

$contacts = Invoke-Api GET '/emergency/contacts' $null $token
Assert-Step 'Numeros de emergencia' ($contacts.ok -and $contacts.response.data.Count -eq 4) ($contacts.error.error.message)

$emergencyRoute = Invoke-Api POST '/emergency/route' @{ origin = @{ lat = -16.5000; lng = -68.1300 } } $token
Assert-Step 'Ruta de urgencia al hospital mas rapido (requiere seeds)' ($emergencyRoute.ok -and $emergencyRoute.response.data.recommended) ($emergencyRoute.error.error.message)

$facilities = Invoke-Api GET '/emergency/facilities/near?lat=-16.5000&lng=-68.1300&radius=3000' $null $token
Assert-Step 'Hospitales y policia cercanos' $facilities.ok ($facilities.error.error.message)

$riskZones = Invoke-Api GET '/safety/risk-zones?activeAt=2026-07-16T22:00:00' $null $token
Assert-Step 'Zonas de riesgo activas a las 22:00' $riskZones.ok ($riskZones.error.error.message)

$government = Invoke-Api GET '/government/congestion/summary' $null $token
Assert-Step 'Vista gobierno bloqueada para ciudadanos (FORBIDDEN_ROLE)' ($government.error.error.code -eq 'FORBIDDEN_ROLE') ($government.raw)

$assistant = Invoke-Api POST '/assistant/chat' @{ message = 'Hola, como llego al centro?' } $token
Assert-Step 'Asistente responde (o avisa que Foundry no esta configurado)' ($assistant.ok -or $assistant.error.error.code -in @('AI_AGENT_NOT_CONFIGURED', 'AI_AGENT_UNAVAILABLE')) ($assistant.raw)

Write-Host "`nResultado final: $script:passed OK, $script:failed fallos`n"
exit ([int]($script:failed -gt 0))
