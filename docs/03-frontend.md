# Ayni Ruta — Diseño del Frontend (Flutter)

> Este documento toma los mismos flujos de [01-flujos-y-hu.md](01-flujos-y-hu.md) y los baja al diseño de la app móvil Flutter. Incluye **el contexto completo del backend** ([02-backend.md](02-backend.md)) porque el back se desarrolla primero: el front se construye contra los contratos que se definen ahí.

## Contexto del backend que el front debe conocer

- **Base URL**: `https://<backend>/api/v1`. Todas las respuestas vienen en el sobre `{ "data": ..., "error": null }` / `{ "data": null, "error": { "code", "message" } }`.
- **Auth**: registro/login/refresh se hacen **directo contra Supabase Auth con el SDK `supabase_flutter`**. Para el resto, la app llama a la API NestJS con `Authorization: Bearer <accessToken de Supabase>`. Tras el primer login se llama `POST /users/me/bootstrap`.
- **La app nunca toca Postgres ni Google Directions directamente**; solo Supabase Auth (sesión), Supabase Storage (subir foto de reporte) y la API NestJS. El mapa y su capa de tráfico sí son del SDK de Google Maps en el cliente.
- **Endpoints por flujo** (detalle completo de request/response en 02-backend.md):

| Flujo | Endpoints |
|---|---|
| 0 Perfil | `POST /users/me/bootstrap`, `GET /users/me`, `PATCH /users/me` |
| 1 Rutas | `POST /routing/recommendations`, `GET /transports/lines`, `GET /transports/lines/:id/stops` |
| 2 Colaboración | `POST /trips`, `PATCH /trips/:id/finish`, `POST /collaboration/shares`, `POST /collaboration/shares/:id/pings`, `PATCH /collaboration/shares/:id/stop`, `POST /collaboration/vehicle-queries`, `GET /users/me/ayni` |
| 3 Urgencia | `POST /emergency/route`, `GET /emergency/contacts`, `GET /emergency/facilities/near` |
| 4 Incidentes | `POST /incidents`, `POST /incidents/:id/votes`, `GET /incidents/active?bbox=`, `GET /incidents/pending/near` |
| 5 Agente IA | `POST /assistant/chat`, `POST /assistant/voice-route` |
| 7 Seguridad | `GET /safety/risk-zones` |
| 8 Gobierno | `GET /government/congestion/summary`, `GET /government/incidents` |

- **Objeto central `RouteOption`** (respuesta de `/routing/recommendations`): lista de `legs`, cada leg con `mode` (`walk | cable_car | pumakatari | minibus | micro | trufi | taxi`), `durationMinutes`, `distanceMeters`, `costBs`, `polyline`, y datos de línea/paradas cuando aplica. La opción trae `totalDurationMinutes`, `totalCostBs`, `safetyScore` y `avoidsIncidents`. **El reordenado por prioridad (tiempo/costo/seguridad) se hace en el cliente sin volver a llamar a la API.**
- **Puntos Ayni**: consultar un transporte cuesta puntos; si el back responde `{ "available": false }` no se cobró y hay que decirlo con honestidad. Compartir ubicación manda un ping cada ~15 s a `/collaboration/shares/:id/pings`.

## Stack del cliente

| Pieza | Elección |
|---|---|
| Framework | Flutter (Dart) |
| Estado | Riverpod |
| Navegación | go_router |
| HTTP | dio (interceptor que inyecta el JWT y desenvuelve el sobre `data/error`) |
| Auth/Storage | supabase_flutter |
| Mapa | google_maps_flutter (+ capa de tráfico nativa) |
| Voz | speech_to_text + flutter_tts (Flujo 5) |
| Modelos | freezed + json_serializable |

## Arquitectura de carpetas (clean por módulos)

```
lib/
├── main.dart
├── app/                      # MaterialApp, router, tema, providers raíz
├── core/
│   ├── api/                  # cliente dio, sobre data/error, excepciones
│   ├── supabase/             # inicialización y sesión
│   ├── location/             # servicio GPS compartido
│   └── widgets/              # botones, mapas base, estados de carga/error
└── modules/
    └── <modulo>/
        ├── domain/           # entidades + contratos de repositorio
        ├── data/             # modelos JSON + implementación de repositorios (API)
        └── presentation/     # pantallas, widgets, providers/controllers
```

Módulos espejo del backend: `auth`, `profile`, `routing`, `trips`, `collaboration`, `emergency`, `incidents`, `assistant`, `safety`, `government`.

---

## Flujo 0 — Onboarding, autenticación y perfil

**Pantallas:** Splash → Bienvenida/Onboarding (3 slides) → Login / Registro → Preferencias iniciales → Home.

| Pantalla | HU | Detalle |
|---|---|---|
| `RegisterScreen` | HU-0.1 | Form correo/contraseña (validación local: email válido, 8+ chars). `supabase.auth.signUp` → `POST /users/me/bootstrap`. |
| `LoginScreen` | HU-0.2 | `signInWithPassword`; la sesión persiste sola con el SDK. Errores de credenciales en el form, no en snackbar genérico. |
| `PreferencesOnboardingScreen` | HU-0.3 | Dos pasos: perfil de accesibilidad (ninguno/visual/movilidad reducida) y prioridad por defecto (rápido/barato/seguro). `PATCH /users/me`. |
| `ProfileScreen` | HU-0.4 | Muestra `GET /users/me`: nombre, correo, saldo Ayni destacado, preferencias editables. |

**Estado:** `authStateProvider` (stream de sesión Supabase) decide la ruta raíz: sin sesión → login, con sesión → home. `profileProvider` cachea `GET /users/me`.

## Flujo 1 — Planificación de viaje multimodal (núcleo)

**Pantallas:** `HomeMapScreen` (mapa + buscador) → `RouteOptionsScreen` (lista de opciones) → `RouteDetailScreen` (tramos + mapa) → inicia Flujo 2.

| Elemento | HU | Detalle |
|---|---|---|
| Buscador con autocompletado | HU-1.1 | Campo "¿A dónde vas?" sobre el mapa; sugerencias de Places (vía SDK), o long-press en el mapa para fijar destino. Origen = GPS actual, editable. |
| Lista de opciones | HU-1.2 | Tarjetas: fila de íconos de los modos usados, tiempo total, costo total en Bs, distancia. Badge "evita bloqueo en …" cuando `avoidsIncidents` no está vacío (HU-1.5). |
| Toggle Tiempo/Costo/Seguridad | HU-1.3, 6.2 | Chips arriba de la lista; **reordena localmente** la misma respuesta. Valor inicial = preferencia del perfil. |
| Detalle de ruta | HU-1.4, 6.1 | Timeline vertical de tramos (ícono, nombre de línea con su color, parada de subida/bajada, minutos, Bs por tramo) + polylines por tramo pintadas en el mapa con el color de la línea. |
| Opción caminando | HU-1.6 | Tarjeta extra cuando el destino está a < 2 km. |
| Botón "Iniciar viaje" | → Flujo 2 | `POST /trips` con la opción elegida. |

**Estado:** `routeRequestProvider` (origen/destino/prioridad) → `recommendationsProvider` (llama `POST /routing/recommendations`, expone loading/data/error) → `sortedOptionsProvider` (reordena por prioridad activa).

## Flujo 2 — Viaje en curso, colaboración y puntos Ayni

**Pantallas:** `ActiveTripScreen` (mapa con ruta y posición) + `AyniHistoryScreen`.

| Elemento | HU | Detalle |
|---|---|---|
| Seguimiento en mapa | HU-2.1 | Posición GPS sobre la polyline activa; banner con el paso actual ("Baja en Estación Libertador"); aviso vibración+banner al acercarse a bajada/transbordo. |
| Diálogo "compartir ubicación" | HU-2.2 | Al empezar un tramo en transporte: opt-in con explicación de puntos. Si acepta → `POST /collaboration/shares` y timer que manda ping cada 15 s. Botón visible para dejar de compartir → `PATCH .../stop`, muestra puntos ganados. |
| Consulta "¿dónde viene?" | HU-2.3 | En la espera de un transporte: botón con el costo en puntos → confirma → `POST /collaboration/vehicle-queries`. Pinta el vehículo estimado en el mapa con ETA. Si `available: false`: mensaje honesto "aún no hay colaboradores en esta línea" y aviso de que no se cobró. |
| Saldo e historial | HU-2.4 | Chip de saldo en Home y perfil; `AyniHistoryScreen` lista `GET /users/me/ayni` (fecha, motivo, +/-). |

**Estado:** `activeTripProvider` (viaje + tramo actual derivado del GPS), `locationShareProvider` (share activo, timer de pings), `ayniBalanceProvider`.

**Permisos:** ubicación en uso (obligatoria para viaje) y en segundo plano solo mientras comparte; pedir con pantalla previa que explique el porqué.

## Flujo 3 — Modo urgencia

**Pantallas:** botón SOS persistente en Home → `EmergencyConfirmSheet` → `EmergencyModeScreen`.

| Elemento | HU | Detalle |
|---|---|---|
| Botón SOS + confirmación | HU-3.1 | FAB rojo siempre visible; bottom sheet de confirmación (evita toques accidentales). Al confirmar, tema cambia a modo urgencia: alto contraste, tipografía grande, mínima información. |
| Ruta al hospital | HU-3.2 | `POST /emergency/route` con la ubicación actual; muestra el hospital elegido, tiempo estimado y hasta 2 alternativas ("prefiero otro"). |
| Números de emergencia | HU-3.3 | Fila fija de botones de llamada directa (`url_launcher` con `tel:`): 911, 165, 160 Ambulancias, Red 114 GAMLP. Visible sin salir de la navegación. |
| Capa salud/policía | HU-3.4 | Markers propios (cruz verde / escudo azul) de `GET /emergency/facilities/near` en **todo** viaje activo; tocar → nombre + "redirigir aquí". |

## Flujo 4 — Reportes y verificación de vías

**Pantallas:** `ReportIncidentScreen`, `IncidentDetailSheet`, capa de incidentes en el mapa.

| Elemento | HU | Detalle |
|---|---|---|
| Reportar incidente | HU-4.1 | FAB "Reportar" en Home: tipo (bloqueo/movilización/refacción), pin en mapa (default: ubicación actual), descripción corta, foto opcional → sube a Supabase Storage → `POST /incidents` con la URL. Feedback: "tu reporte espera confirmación de otros vecinos". |
| Confirmar reportes | HU-4.2 | Al estar cerca de un `pending` (`GET /incidents/pending/near`), aparece tarjeta: "¿Sigue el bloqueo en …?" con [Sí, sigue] [Ya no está] → `POST /incidents/:id/votes`. |
| Capa de incidentes | HU-4.4 | Markers por tipo, color por origen (dorado = oficial, naranja = ciudadano verificado). `GET /incidents/active?bbox=` al mover el mapa (debounce). Tocar → sheet con detalle, foto, confirmaciones. |
| Tráfico | HU-4.5 | `trafficEnabled: true` del SDK de Google Maps. Sin código propio. |

## Flujo 5 — Accesibilidad y agente IA

**Pantallas:** `AssistantChatScreen`, modo voz integrado en Home y viaje.

| Elemento | HU | Detalle |
|---|---|---|
| Pedir ruta por voz | HU-5.1 | Botón micrófono grande en Home (protagonista si el perfil es `visual`): speech_to_text captura el destino → `POST /assistant/voice-route` → el agente confirma por TTS lo entendido antes de calcular. Semántica completa para TalkBack/VoiceOver en toda la app. |
| Guía por voz en viaje | HU-5.2 | Con perfil `visual`, cada cambio de tramo y proximidad de bajada se anuncia con flutter_tts; gesto de doble tap para repetir la última indicación; comando de voz para números de emergencia. |
| Rutas accesibles | HU-5.3 | Con perfil `reduced_mobility`, el request de rutas manda `accessibility: reduced_mobility` (el back hace el trabajo); el detalle muestra el badge "ruta accesible" y el porqué. |
| Chat del agente | HU-5.4 | Chat simple (burbujas) → `POST /assistant/chat` con `tripId` y ubicación; cuando la respuesta trae `isCommunityEstimate: true`, se muestra la etiqueta "estimación de la comunidad". |

## Flujo 6 — Capa de costos

Sin pantallas propias: vive en el Flujo 1.
- Bs visible en cada tarjeta de opción y cada tramo del detalle (HU-6.1).
- Chip "Costo" del toggle = orden de más barata a más cara (HU-6.2).
- Con prioridad "Seguridad", las opciones que reemplazan caminata por taxi muestran el badge "tramo en taxi por seguridad" con la diferencia de costo (HU-6.3, HU-7.2).

## Flujo 7 — Seguridad ciudadana

| Elemento | HU | Detalle |
|---|---|---|
| Aviso de zona de riesgo | HU-7.1 | Al calcular o durante el viaje, si la ruta cruza una zona de `GET /safety/risk-zones` en su franja: banner ámbar no bloqueante "esta zona registra robos en este horario". |
| Sugerencia de taxi | HU-7.2 | El banner ofrece "ver opción en taxi" → selecciona la alternativa con tramo en taxi ya calculada. |

## Flujo 8 — Vista de gobierno

| Elemento | HU | Detalle |
|---|---|---|
| Acceso por rol | HU-8.1 | Si `GET /users/me` devuelve `role: government`, el drawer muestra "Monitoreo". Cuentas demo pre-creadas. |
| `GovernmentDashboardScreen` | HU-8.2 | Mapa de calor/clusters de `GET /government/incidents` + tarjetas resumen de `GET /government/congestion/summary`, filtros por tipo y rango de fechas. |

---

## Orden de desarrollo sugerido (después del backend)

1. `core/` (cliente dio + sobre de errores + Supabase init) y Flujo 0 completo.
2. `HomeMapScreen` + Flujo 1 contra el motor real (es el demo central).
3. Flujo 4 (reportes + capa de incidentes) — hace visible el diferencial en el mapa.
4. Flujo 2 (compartir/consultar + puntos Ayni).
5. Flujo 3 y 7 (urgencia y seguridad, reutilizan mapa y motor).
6. Flujo 5 (voz + chat) y Flujo 8 (dashboard) con escenarios de demo.

## Lineamientos de UI

- Identidad: colores de las líneas del teleférico como paleta de acentos; el color de cada tramo en el mapa = color real de la línea.
- Todo texto de la app en español; montos siempre "Bs".
- Estados vacíos y de error con mensajes honestos y accionables (nunca pantallas en blanco).
- Accesibilidad transversal: targets ≥ 48dp, contraste AA, labels semánticos en todos los controles.
