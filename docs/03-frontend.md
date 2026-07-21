# Chasqui — Diseño del Frontend (Flutter)

> Este documento toma los flujos de [01-flujos-y-hu.md](01-flujos-y-hu.md) y los baja al diseño de la app móvil Flutter, organizado según el **desglose de pantallas definido en FigJam (julio 2026)**: Inicio, Rutas, Chatbot, Emergencias, Denuncias, Perfil y Comunidad/apoyo. Incluye el contexto del backend ([02-backend.md](02-backend.md)) porque el back se desarrolla primero: el front se construye contra los contratos que se definen ahí. **Todos los endpoints listados ya están implementados en el backend.**

## Contexto del backend que el front debe conocer

- **Base URL**: `https://<backend>/api/v1`. Todas las respuestas vienen en el sobre `{ "data": ..., "error": null }` / `{ "data": null, "error": { "code", "message" } }`.
- **Auth**: registro/login/refresh se hacen **directo contra Supabase Auth con el SDK `supabase_flutter`**. Para el resto, la app llama a la API NestJS con `Authorization: Bearer <accessToken de Supabase>`. Tras el primer login se llama `POST /users/me/bootstrap`.
- **La app nunca toca Postgres ni Google Directions directamente**; solo Supabase Auth (sesión), Supabase Storage (subir foto de reporte) y la API NestJS. El mapa y su capa de tráfico sí son del SDK de Google Maps en el cliente.
- **Endpoints por pantalla** (detalle completo de request/response en 02-backend.md):

| Pantalla | Endpoints |
|---|---|
| Inicio / Viaje inteligente | `POST /routing/recommendations`, `POST /trips`, `PATCH /trips/:id/finish` |
| Inicio / Historial de viajes | `GET /users/me/trips?page&pageSize` |
| Rutas (catálogo) | `GET /transports/lines`, `GET /transports/lines/:id/stops`, `GET /incidents/active?bbox=` |
| Chatbot | `POST /assistant/chat`, `POST /assistant/voice-route` |
| Emergencias | `POST /emergency/route`, `GET /emergency/contacts`, `GET /emergency/facilities/near` |
| Denuncias | `POST /complaints`, `GET /complaints/mine` |
| Perfil | `POST /users/me/bootstrap`, `GET /users/me`, `PATCH /users/me`, `GET /users/me/ayni` |
| Comunidad / apoyo | `GET /community/lines/:lineId/activity`, `POST /community/questions`, `GET /community/questions/mine`, `GET /community/questions/pending`, `POST /community/questions/:id/answers`, `POST /collaboration/shares`, `.../pings`, `.../stop` |
| Incidentes (capa transversal) | `POST /incidents`, `POST /incidents/:id/votes`, `GET /incidents/active?bbox=`, `GET /incidents/pending/near` |
| Seguridad (capa transversal) | `GET /safety/risk-zones` |
| Gobierno | `GET /government/congestion/summary`, `GET /government/incidents` |

- **Objeto central `RouteOption`** (respuesta de `/routing/recommendations`): lista de `legs`, cada leg con `mode` (`walk | cable_car | pumakatari | minibus | micro | trufi | taxi`), `durationMinutes`, `distanceMeters`, `costBs`, `polyline`, y datos de línea/paradas cuando aplica. La opción trae `totalDurationMinutes`, `totalCostBs`, `safetyScore` y `avoidsIncidents`. **El reordenado por prioridad (tiempo/costo/seguridad) se hace en el cliente sin volver a llamar a la API.**
- **Puntos Chass**: la economía de puntos es **persona a persona**. Se ganan respondiendo preguntas de la comunidad (`answered_question`), compartiendo ubicación durante un viaje (`shared_location`) y reportando bloqueos que se verifican (`verified_report`); se gastan haciendo preguntas a personas activas en una ruta (`asked_question`). Si no hay personas activas la pregunta no se cobra (`409 NO_ACTIVE_COLLABORATORS`); si nadie responde antes del timeout, los puntos se devuelven solos (`question_refunded`) — en ambos casos decirlo con honestidad. Compartir ubicación manda un ping cada ~15 s a `/collaboration/shares/:id/pings` y es lo que te marca como "persona activa en la ruta". `POST /collaboration/vehicle-queries` (estimación automática) queda deprecado para el front.

## Stack del cliente

| Pieza | Elección |
|---|---|
| Framework | Flutter (Dart) |
| Estado | Riverpod |
| Navegación | go_router |
| HTTP | dio (interceptor que inyecta el JWT y desenvuelve el sobre `data/error`) |
| Auth/Storage | supabase_flutter |
| Mapa | google_maps_flutter (+ capa de tráfico nativa) |
| Voz | speech_to_text + flutter_tts (Chatbot / accesibilidad) |
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

Módulos: `auth`, `profile`, `routing`, `transports` (catálogo de rutas), `trips`, `community` (comunidad/apoyo + Puntos Chass, evolución de `collaboration`), `emergency`, `incidents`, `complaints` (denuncias), `assistant` (chatbot), `safety`, `government`.

---

## Mapa de pantallas y navegación

La app tiene **una pantalla principal (Inicio) y seis secciones**, según el desglose de FigJam:

```
Inicio (mapa)
├── Viaje inteligente  → opciones → detalle → viaje en curso
├── Modo emergencia    → SOS: hospitales cercanos o centros policiales
├── Historial de viajes anteriores
└── pop-up Comunidad: "ayudar a esta persona" [Ayudar] [Cancelar]

Secciones: 1 Rutas · 2 Chatbot · 3 Emergencias · 4 Denuncias · 5 Perfil · Comunidad/apoyo
```

**Navegación propuesta**: bottom navigation con Inicio · Rutas · Chatbot · Comunidad · Perfil. Emergencias se activa desde el FAB SOS persistente (visible en toda la app, no como tab). Denuncias es accesible desde el catálogo de Rutas (denunciar un vehículo de esa línea) y desde Perfil.

---

## Pantalla de inicio

**Contenido:** mapa de La Paz con tráfico + tres accesos principales y el pop-up de comunidad.

| Elemento | HU | Detalle |
|---|---|---|
| Viaje inteligente | HU-1.1 → 1.5 | Buscador "¿A dónde vas?" sobre el mapa; abre el flujo de planificación multimodal (ver siguiente sección). |
| Modo emergencia | HU-3.1 → 3.3 | FAB SOS rojo persistente; SOS a hospitales cercanos o centros policiales (ver pantalla Emergencias). |
| Historial de viajes anteriores | HU-2.8 | Lista de viajes pasados desde `GET /users/me/trips` (fecha, `routeSnapshot` con origen → destino, modos y costo); tocar uno re-pide esa ruta. |
| Pop-up "ayudar a esta persona" | HU-2.7 | Al abrir la app (y periódicamente con share activo), `GET /community/questions/pending`; si hay preguntas, pop-up [Ayudar] / [Cancelar]. Al dar Ayudar se ven las preguntas y responderlas acredita puntos (ver Comunidad). |
| Chip de saldo de Puntos Chass | HU-2.4 | Saldo visible en el header; toca → historial de puntos en Perfil. |

### Viaje inteligente (flujo núcleo, HU-1.x)

**Pantallas:** `HomeMapScreen` (buscador) → `RouteOptionsScreen` → `RouteDetailScreen` → `ActiveTripScreen`.

| Elemento | HU | Detalle |
|---|---|---|
| Buscador con autocompletado | HU-1.1 | Sugerencias de Places (vía SDK) o long-press en el mapa. Origen = GPS actual, editable. |
| Lista de opciones | HU-1.2 | Tarjetas: íconos de modos, tiempo total, costo total en Bs, distancia. Badge "evita bloqueo en …" cuando `avoidsIncidents` no está vacío (HU-1.5). |
| Toggle Tiempo/Costo/Seguridad | HU-1.3, 6.2 | Chips arriba de la lista; **reordena localmente**. Valor inicial = preferencia del perfil. |
| Detalle de ruta | HU-1.4, 6.1 | Timeline vertical de tramos (ícono, línea con su color, paradas, minutos, Bs) + polylines por tramo en el mapa. |
| Opción caminando | HU-1.6 | Tarjeta extra cuando el destino está a < 2 km. |
| Botón "Iniciar viaje" | HU-2.1 | `POST /trips`; abre `ActiveTripScreen`: posición GPS sobre la polyline, banner del paso actual, aviso al acercarse a bajada/transbordo. Al subir a un transporte, diálogo opt-in de compartir ubicación (HU-2.2, gana puntos). |

**Estado:** `routeRequestProvider` → `recommendationsProvider` → `sortedOptionsProvider`; `activeTripProvider` y `locationShareProvider` durante el viaje.

**Permisos:** ubicación en uso (obligatoria para viaje) y en segundo plano solo mientras comparte; pedir con pantalla previa que explique el porqué.

---

## 1 — Rutas (catálogo por tipo de transporte)

**Pantallas:** `TransportCatalogScreen` (secciones) → `LineDetailScreen` (línea con paradas en mapa).

| Elemento | HU | Detalle |
|---|---|---|
| Sección Teleférico | HU-1.8 | Las 11 líneas con su color real: recorrido, estaciones y costo por línea (`GET /transports/lines?type=cable_car` + `/stops`). |
| Sección PumaKatari | HU-1.8 | Rutas con paradas y costos. |
| Sección minibuses / micros / trufis | HU-1.8 | Rutas con paradas y costos promedio. |
| Bloqueos y caminos alternos | HU-1.8, 4.4 | Sobre cada línea se marcan los incidentes activos que la afectan (`GET /incidents/active`) y se sugiere el camino alterno. |
| Botón "Reportar bloqueo/desvío" | HU-4.1 | Abre el formulario de reporte del flujo de incidentes; cuando el reporte pasa a `active`, el backend acredita `AYNI_VERIFIED_REPORT_REWARD` puntos al autor (movimiento `verified_report`). |
| Acceso a Denuncias | HU-9.1 | Desde el detalle de una línea: "denunciar un vehículo de esta línea" (pre-llena línea/parada). |

**Estado:** `linesProvider(type)` cachea el catálogo por tipo; `lineDetailProvider(id)` junta paradas + incidentes activos sobre la polyline de la línea.

---

## 2 — Chatbot

**Pantallas:** `AssistantChatScreen` con dos entradas; modo voz integrado en Inicio y viaje.

| Elemento | HU | Detalle |
|---|---|---|
| Responder preguntas frecuentes | HU-5.6 | Accesos rápidos (chips) con las dudas típicas: horarios del teleférico, tarifas, cómo funcionan los Puntos Chass; responde el agente (`POST /assistant/chat`). |
| Preguntar de una ruta en específico | HU-5.6, 5.4 | Chat libre (burbujas) con `tripId` y ubicación como contexto; si la respuesta trae `isCommunityEstimate: true`, etiqueta "estimación de la comunidad". |
| Pedir ruta por voz | HU-5.1 | Botón micrófono grande (protagonista si el perfil es `visual`): speech_to_text → `POST /assistant/voice-route` → confirma por TTS antes de calcular. Semántica completa para TalkBack/VoiceOver. |
| Guía por voz en viaje | HU-5.2 | Con perfil `visual`, cada cambio de tramo y proximidad de bajada se anuncia con flutter_tts; doble tap repite la última indicación; comando de voz para números de emergencia. |
| Rutas accesibles | HU-5.3 | Con perfil `reduced_mobility`, el request de rutas manda `accessibility: reduced_mobility`; el detalle muestra el badge "ruta accesible" y el porqué. |

---

## 3 — Emergencias

**Pantallas:** FAB SOS persistente → `EmergencyConfirmSheet` → `EmergencyModeScreen`.

| Elemento | HU | Detalle |
|---|---|---|
| Botón SOS + confirmación | HU-3.1 | Bottom sheet de confirmación (evita toques accidentales). Al confirmar, tema cambia a modo urgencia: alto contraste, tipografía grande, mínima información. |
| Ruta al hospital / centro policial | HU-3.2 | `POST /emergency/route` con la ubicación actual; muestra el centro elegido, tiempo estimado y hasta 2 alternativas ("prefiero otro"). Los centros policiales cercanos se ofrecen como redirección desde la capa de facilities. |
| Números de emergencia | HU-3.3 | Fila fija de botones de llamada directa (`url_launcher` con `tel:`): 911, 165, 160 Ambulancias, Red 114 GAMLP. Visible sin salir de la navegación. |
| Capa salud/policía | HU-3.4 | Markers propios (cruz verde / escudo azul) de `GET /emergency/facilities/near` en **todo** viaje activo; tocar → nombre + "redirigir aquí". |

---

## 4 — Denuncias (pantalla nueva)

**Pantallas:** `ComplaintFormScreen` → confirmación → `MyComplaintsScreen`.

| Elemento | HU | Detalle |
|---|---|---|
| Identificación del vehículo | HU-9.1 | Campo placa o número del vehículo (`vehicleIdentifier`). Si el transporte es teleférico → selector de línea y estación; si es PumaKatari → selector de ruta y parada (ambos desde el catálogo de `transports`, no texto libre; el back valida que la parada pertenezca a la línea). Se exige placa **o** línea (`400 VEHICLE_OR_LINE_REQUIRED`). |
| Reclamo | HU-9.1 | Texto del reclamo (cobro indebido, maltrato, imprudencia, otro), máx. 1000 caracteres. |
| Envío | HU-9.1 | `POST /complaints` → nace `submitted`; confirmación clara: "tu denuncia quedó registrada". `GET /complaints/mine` lista las propias. |

**Estado:** `complaintFormProvider` (tipo de transporte elegido decide qué selectores mostrar), `myComplaintsProvider`.

---

## 5 — Perfil

**Pantallas:** `ProfileScreen` con tres bloques (el desglose de FigJam lo marca como fase 2, pero preferencias y cuenta ya son MVP del Flujo 0).

| Bloque | HU | Detalle |
|---|---|---|
| Mis preferencias | HU-0.3, 0.4 | Perfil de accesibilidad (ninguno/visual/movilidad reducida) y prioridad por defecto (rápido/barato/seguro); editable, `PATCH /users/me`. |
| Información de la cuenta | HU-0.4 | Nombre, correo, saldo de Puntos Chass destacado con historial de movimientos (`GET /users/me/ayni`: fecha, motivo, +/-). |
| Enlazar con cuentas familiares | HU-0.6 ⚪ | Futuro (fase 2): no se construye para la hackatón; puede mostrarse como "próximamente" en el demo. |

**Onboarding y auth (Flujo 0):** Splash → Bienvenida (3 slides) → `LoginScreen` / `RegisterScreen` (Supabase Auth, validación local de email y 8+ chars; tras registro `POST /users/me/bootstrap`) → `PreferencesOnboardingScreen` (2 pasos, `PATCH /users/me`) → Inicio. `authStateProvider` (stream de sesión Supabase) decide la ruta raíz; `profileProvider` cachea `GET /users/me`.

---

## Comunidad / apoyo (pantalla nueva)

El corazón del sistema de Puntos Chass: **preguntas persona a persona** sobre una ruta ("SOS usuario a usuario"). Evolución de la antigua consulta automática "¿dónde viene mi transporte?".

**Pantallas:** `CommunityScreen` (elegir ruta y preguntar) + pop-up "ayudar a esta persona" (global, se muestra en Inicio) + `AyniHistoryScreen`.

| Elemento | HU | Detalle |
|---|---|---|
| Elegir ruta y ver personas activas | HU-2.3 | El usuario indica a qué ruta quiere ir; `GET /community/lines/:lineId/activity` → `{ activePeople }` (nunca identidad ni posición individual). Con 0 personas, el botón de preguntar se deshabilita con el mensaje honesto. |
| Preguntar (gastar puntos) | HU-2.3 | `POST /community/questions` con `kind: availability \| arrival_time \| seats` y detalle opcional; muestra el costo (`pointsCost`) y confirma antes de enviar. La app hace polling de `GET /community/questions/mine` hasta que llegue la respuesta o expire (`expiresAt`); si expira, el back ya devolvió los puntos (`question_refunded`) y se avisa "nadie respondió, te devolvimos tus puntos". |
| Pop-up "ayudar a esta persona" | HU-2.7 | `GET /community/questions/pending` (preguntas de las rutas donde tengo share activo) → pop-up [Ayudar] / [Cancelar]; al dar Ayudar, `POST /community/questions/:id/answers` responde y acredita los puntos que gastó quien preguntó (`{ pointsAwarded, newBalance }`). La primera respuesta cierra la pregunta (`409 QUESTION_ALREADY_ANSWERED` para el resto). Cancelar no penaliza. |
| Compartir ubicación (estar "activo") | HU-2.2 | Al empezar un tramo en transporte: opt-in con explicación de puntos → `POST /collaboration/shares` + ping cada 15 s. Compartir es lo que marca al usuario como "persona activa en la ruta" (habilita ver y responder preguntas de esa línea). Botón visible para dejar de compartir → `PATCH .../stop`, muestra puntos ganados. |
| Saldo e historial | HU-2.4 | Chip de saldo en Inicio y Perfil; `AyniHistoryScreen` lista `GET /users/me/ayni` (motivos: `answered_question`, `shared_location`, `verified_report`, `asked_question`, `question_refunded`). |

**Estado:** `communityQuestionProvider` (pregunta activa + polling de respuestas), `helpRequestsProvider` (preguntas pendientes de mis rutas activas → alimenta el pop-up), `locationShareProvider`, `ayniBalanceProvider`.

---

## Capas transversales del mapa

| Capa | HU | Detalle |
|---|---|---|
| Incidentes | HU-4.1, 4.2, 4.4 | FAB "Reportar" en Inicio: tipo (bloqueo/movilización/refacción), pin en mapa, descripción, foto opcional (Supabase Storage) → `POST /incidents`. Cerca de un `pending`: tarjeta "¿Sigue el bloqueo en …?" [Sí, sigue] [Ya no está] → `POST /incidents/:id/votes`. Markers por tipo, color por origen (dorado = oficial, naranja = ciudadano verificado); `GET /incidents/active?bbox=` con debounce al mover el mapa. |
| Tráfico | HU-4.5 | `trafficEnabled: true` del SDK de Google Maps. Sin código propio. |
| Zonas de riesgo | HU-7.1, 7.2 | Si la ruta cruza una zona de `GET /safety/risk-zones` en su franja horaria: banner ámbar no bloqueante "esta zona registra robos en este horario" + botón "ver opción en taxi" que selecciona la alternativa con tramo en taxi ya calculada. |
| Costos (Flujo 6) | HU-6.1 → 6.3 | Bs visible en cada tarjeta y tramo; chip "Costo" = orden de más barata a más cara; con prioridad "Seguridad", badge "tramo en taxi por seguridad" con la diferencia de costo. |

## Vista de gobierno

| Elemento | HU | Detalle |
|---|---|---|
| Acceso por rol | HU-8.1 | Si `GET /users/me` devuelve `role: government`, el drawer muestra "Monitoreo". Cuentas demo pre-creadas. |
| `GovernmentDashboardScreen` | HU-8.2 | Mapa de calor/clusters de `GET /government/incidents` + tarjetas resumen de `GET /government/congestion/summary`, filtros por tipo y rango de fechas. |

---

## Estado del backend para estas pantallas

Todo lo que el desglose de pantallas exige ya está implementado en el backend (diseño detallado en [02-backend.md](02-backend.md)):

| Funcionalidad | Estado |
|---|---|
| Comunidad: preguntas usuario a usuario (HU-2.3, 2.7) | ✅ Módulo `community`: actividad por línea, preguntar (atómico con puntos), pop-up de pendientes, responder, reembolso automático por timeout (job cada minuto) |
| Historial de viajes (HU-2.8) | ✅ `GET /users/me/trips` en el módulo `trips` |
| Denuncias (HU-9.1) | ✅ Módulo `complaints`: `POST /complaints` + `GET /complaints/mine` |
| Puntos por reporte verificado (HU-4.1) | ✅ Al pasar un incidente a `active` se acreditan puntos al autor una sola vez (índice único en BD) |
| Cuentas familiares (HU-0.6) | ⚪ Futuro, no se implementa para la hackatón |

> Requisito de despliegue: volver a ejecutar `backend/seeds/00-schema.sql` en el SQL Editor de Supabase (es idempotente) para crear las tablas `community_questions`, `community_answers`, `complaints` y las funciones RPC nuevas.

## Orden de desarrollo sugerido (después del backend)

1. `core/` (cliente dio + sobre de errores + Supabase init) y Flujo 0 completo (auth + Perfil con preferencias y cuenta).
2. Inicio + Viaje inteligente contra el motor real (es el demo central).
3. Rutas (catálogo por transporte) — reutiliza `GET /transports/*` ya existente — y la capa de incidentes/reportes.
4. Comunidad/apoyo (preguntas usuario a usuario + pop-up ayudar + compartir ubicación + Puntos Chass) contra el módulo `community` ya implementado.
5. Emergencias y zonas de riesgo (reutilizan mapa y motor).
6. Chatbot (FAQ + ruta específica + voz), Denuncias e Historial de viajes.
7. Vista de gobierno con escenarios de demo.

## Lineamientos de UI

- Identidad: colores de las líneas del teleférico como paleta de acentos; el color de cada tramo en el mapa = color real de la línea.
- Todo texto de la app en español; montos siempre "Bs".
- Estados vacíos y de error con mensajes honestos y accionables (nunca pantallas en blanco). En Comunidad, "aún no hay personas activas en esta ruta" es un estado esperado, no un error.
- Accesibilidad transversal: targets ≥ 48dp, contraste AA, labels semánticos en todos los controles.
