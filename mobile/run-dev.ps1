param([string]$Device = '')

$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$envFile = Join-Path $PSScriptRoot '.env'
if (-not (Test-Path $envFile)) {
    Write-Host 'No existe mobile\.env. Copia .env.example como .env y llena los valores:' -ForegroundColor Yellow
    Write-Host '  Copy-Item .env.example .env' -ForegroundColor Yellow
    exit 1
}

$defines = @()
foreach ($line in Get-Content $envFile) {
    if ($line -match '^\s*([^#=]+)=(.+)$') {
        $defines += "--dart-define=$($Matches[1].Trim())=$($Matches[2].Trim())"
    }
}

if ($defines.Count -eq 0) {
    Write-Host 'mobile\.env existe pero no tiene valores; llena SUPABASE_URL, SUPABASE_ANON_KEY y API_BASE_URL.' -ForegroundColor Yellow
    exit 1
}

if ($Device) {
    flutter run -d $Device @defines
} else {
    flutter run @defines
}
