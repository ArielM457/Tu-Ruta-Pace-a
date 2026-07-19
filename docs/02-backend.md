# Chasqui — Diseño del Backend (NestJS)

> Este documento toma los mismos flujos de [01-flujos-y-hu.md](01-flujos-y-hu.md) y los baja al diseño del backend. **El backend se desarrolla primero**; el frontend consume los contratos definidos aquí.

## Stack y responsabilidades

| Pieza | Rol |
|---|---|
| **NestJS (Node/TypeScript)** | API REST, lógica de negocio, motor de recomendación, orquestación |
| **Supabase — Postgres** | Base de datos (accedida desde NestJS con el service role key) |
| **Supabase — Auth** | Registro/login; NestJS valida el JWT de Supabase en cada request |
| **Supabase — Storage** | Fotos de reportes de incidentes |
| **Google Directions / Places** | Base real de tiempos, distancias, geocoding y tráfico |
| **Agente Azure AI Foundry** | IA del proyecto: agente conversacional/accesibilidad consumido por NestJS vía REST (threads/runs del Agent Service) |
| **Azure** | Hosting del backend y servicios IA (ver [04-recursos-azure.md](04-recursos-azure.md)) |

### Principios

- La app móvil **nunca** habla directo con Supabase Postgres ni con Google: todo pasa por la API NestJS. La única excepción es Supabase Auth (login/registro/refresh desde el SDK de Flutter).
- Autenticación: la app manda `Authorization: Bearer <jwt-supabase>`; un guard de NestJS valida el token con el JWT secret de Supabase y extrae `userId` y `role`.
- Todas las respuestas siguen el sobre `{ "data": ..., "error": null }` o `{ "data": null, "error": { "code": "...", "message": "..." } }`.
- Prefijo global: `/api/v1`.

## Arquitectura de módulos NestJS

```
src/
├── main.ts
├── app.module.ts
├── common/                  # guards, decorators, filters, interceptors, DTO base
│   ├── guards/              # SupabaseAuthGuard, RolesGuard
│   ├── decorators/          # @CurrentUser(), @Roles()
│   └── filters/             # filtro global de excepciones → sobre de error
├── config/                  # configuración tipada por variables de entorno
├── integrations/            # clientes de servicios externos
│   ├── supabase/            # cliente Postgres/Storage (service role)
│   ├── google-maps/         # Directions + Places
│   └── ai-agent/            # cliente HTTP hacia los servicios Python
└── modules/
    ├── users/               # Flujo 0 — perfil y preferencias
    ├── routing/             # Flujo 1 y 6 — motor de recomendación multimodal + costos
    ├── transports/          # catálogo: líneas de teleférico, rutas PumaKatari, radiotaxis
    ├── trips/               # Flujo 2 — viajes en curso + historial
    ├── collaboration/       # Flujo 2 — ubicación colaborativa + Puntos Chass
    ├── community/           # Flujo 2 — preguntas usuario a usuario (SOS usuario a usuario)
    ├── emergency/           # Flujo 3 — modo urgencia, hospitales, números
    ├── incidents/           # Flujo 4 — reportes, confirmaciones, cierres oficiales
    ├── complaints/          # Flujo 9 — denuncias de transporte
    ├── safety/              # Flujo 7 — zonas de riesgo
    ├── assistant/           # Flujo 5 — proxy al agente IA
    └── government/          # Flujo 8 — monitoreo agregado
```

Cada módulo sigue la misma estructura interna:

```
modules/<nombre>/
├── <nombre>.module.ts
├── controllers/
├── services/
├── dto/            # request/response con class-validator
└── repositories/   # acceso a datos vía cliente Supabase
```

## Modelo de datos (Supabase Postgres)

> `auth.users` la gestiona Supabase. Todas nuestras tablas van en el esquema `public` con FK a `auth.users.id`.

```sql
-- Flujo 0
profiles (
  id uuid PK = auth.users.id,
  display_name text,
  role text default 'citizen',            -- citizen | government
  accessibility_profile text default 'none', -- none | visual | reduced_mobility
  default_priority text default 'time',   -- time | cost | safety
  ayni_points integer default 0,
  created_at timestamptz
)

-- Catálogo de transporte (semilla propia: no existe API abierta)
transport_lines (
  id uuid PK,
  kind text,               -- cable_car | pumakatari | minibus | micro | trufi | radiotaxi_zone
  name text,               -- "Línea Roja", "Ruta Chasquipampa", "Radio taxi Zona Sur"
  color text,
  fare_bs numeric,         -- tarifa base
  service_start time,      -- teleférico: 05:00
  service_end time,        -- teleférico: 23:00
  is_active boolean
)

transport_stops (
  id uuid PK,
  line_id uuid FK -> transport_lines,
  name text,
  position geography(point),
  sequence integer,        -- orden dentro de la línea
  is_accessible boolean    -- rampa/acceso para movilidad reducida
)

-- Flujo 1
route_requests (           -- histórico de solicitudes (analítica y demo)
  id uuid PK,
  user_id uuid FK,
  origin geography(point),
  destination geography(point),
  priority text,           -- time | cost | safety
  created_at timestamptz
)

-- Flujo 2
trips (
  id uuid PK,
  user_id uuid FK,
  route_snapshot jsonb,    -- la opción elegida, congelada
  status text,             -- active | finished | cancelled
  started_at timestamptz,
  finished_at timestamptz
)

location_shares (
  id uuid PK,
  user_id uuid FK,
  trip_id uuid FK,
  line_id uuid FK -> transport_lines,
  started_at timestamptz,
  ended_at timestamptz,
  points_awarded integer
)

location_pings (
  id bigint PK,
  share_id uuid FK -> location_shares,
  position geography(point),
  recorded_at timestamptz
)

ayni_transactions (
  id uuid PK,
  user_id uuid FK,
  amount integer,          -- + ganó / - gastó
  reason text,             -- shared_location | queried_vehicle | asked_question | answered_question | question_refunded | verified_report | bonus
  reference_id uuid,       -- share, pregunta, respuesta o incidente que la originó
  created_at timestamptz
)

community_questions (      -- SOS usuario a usuario (HU-2.3)
  id uuid PK,
  asker_id uuid FK,
  line_id uuid FK -> transport_lines,
  kind text,               -- availability | arrival_time | seats
  content text nullable,   -- detalle libre opcional
  points_cost integer,     -- lo que pagó el que pregunta
  status text,             -- open | answered | expired
  created_at timestamptz,
  expires_at timestamptz,  -- si nadie responde antes, se reembolsa
  answered_at timestamptz nullable
)

community_answers (        -- respuesta de un colaborador (HU-2.7)
  id uuid PK,
  question_id uuid FK -> community_questions,
  responder_id uuid FK,
  content text,
  points_awarded integer,
  created_at timestamptz
)

-- Flujo 3
health_facilities (
  id uuid PK,
  name text,
  kind text,               -- hospital | clinic | police
  position geography(point),
  phone text
)

-- Flujo 4
incidents (
  id uuid PK,
  reporter_id uuid FK nullable,   -- null si es oficial
  kind text,               -- blockade | protest | roadwork | official_closure
  source text,             -- citizen | official | news
  status text,             -- pending | active | resolved | rejected
  position geography(point),
  affected_area geography(polygon) nullable,
  description text,
  photo_url text,
  confirmations integer default 0,
  denials integer default 0,
  starts_at timestamptz,
  expires_at timestamptz,
  created_at timestamptz
)

incident_votes (
  id uuid PK,
  incident_id uuid FK,
  user_id uuid FK,
  vote text,               -- confirm | deny
  unique (incident_id, user_id)
)

-- Flujo 5
shared_experiences (
  id uuid PK,
  user_id uuid FK,
  zone text,
  time_slot text,          -- ej. "20:00-23:00"
  content text,
  created_at timestamptz
)

-- Flujo 9
complaints (
  id uuid PK,
  user_id uuid FK,
  vehicle_identifier text, -- placa o número del vehículo
  transport_kind text,     -- cable_car | pumakatari | minibus | micro | trufi | taxi
  line_id uuid FK nullable -> transport_lines,   -- teleférico: línea / Puma: ruta
  stop_id uuid FK nullable -> transport_stops,   -- estación o parada
  complaint text,          -- el reclamo
  status text default 'submitted',               -- submitted | in_review | closed (futuro)
  created_at timestamptz
)

-- Flujo 7
risk_zones (
  id uuid PK,
  name text,
  area geography(polygon),
  risk_start time,
  risk_end time,
  level text,              -- medium | high
  source text              -- seeded | reports
)
```

> **Nota de implementación:** el código final guarda las posiciones como columnas `lat`/`lng` (double precision) y calcula cercanías con haversine en la aplicación, en lugar de `geography` + PostGIS. A escala urbana el resultado es equivalente y evita depender de funciones RPC para cada lectura. Las zonas de riesgo se modelan como centro + radio en metros. Las operaciones que exigen atomicidad (Puntos Chass, votos de incidentes) sí usan funciones RPC de Postgres: `adjust_ayni_points` y `register_incident_vote`. El schema real está en `backend/seeds/00-schema.sql`.

---

## Flujo 0 — Onboarding, autenticación y perfil

**Registro y login los hace el SDK de Supabase directamente desde Flutter.** El backend participa así:

| Método | Ruta | HU | Descripción |
|---|---|---|---|
| `POST` | `/users/me/bootstrap` | HU-0.1 | Idempotente. Tras el primer login crea el `profile` con 0 puntos. |
| `GET` | `/users/me` | HU-0.4 | Perfil completo: datos, preferencias, saldo de Puntos Chass. |
| `PATCH` | `/users/me` | HU-0.3, 0.4 | Actualiza `display_name`, `accessibility_profile`, `default_priority`. |

- `SupabaseAuthGuard` global: valida JWT, inyecta `{ userId, role }`.
- `RolesGuard` + `@Roles('government')` para el Flujo 8.

## Flujo 1 — Planificación de viaje multimodal (núcleo)

### Endpoint principal

```
POST /routing/recommendations        (HU-1.1 → 1.6, 6.1 → 6.3)
```

Request:
```json
{
  "origin":      { "lat": -16.5, "lng": -68.13 },
  "destination": { "lat": -16.52, "lng": -68.12 },
  "priority": "time",              // time | cost | safety
  "accessibility": "none"          // none | visual | reduced_mobility (default: del perfil)
}
```

Response (`data`):
```json
{
  "options": [
    {
      "id": "opt-1",
      "totalDurationMinutes": 42,
      "totalDistanceMeters": 8300,
      "totalCostBs": 5.0,
      "safetyScore": 0.9,
      "avoidsIncidents": ["incident-uuid"],
      "legs": [
        {
          "mode": "walk",
          "durationMinutes": 8,
          "distanceMeters": 600,
          "costBs": 0,
          "polyline": "...",
          "instruction": "Camina hasta la estación Sopocachi"
        },
        {
          "mode": "cable_car",
          "lineId": "...", "lineName": "Línea Celeste", "lineColor": "#6EC5E9",
          "boardStop": { "id": "...", "name": "Sopocachi" },
          "alightStop": { "id": "...", "name": "Libertador" },
          "durationMinutes": 11, "costBs": 3.0, "polyline": "..."
        }
      ]
    }
  ],
  "activeIncidentsConsidered": 3
}
```

### Algoritmo del motor (`routing/services/`)

1. **Geocoding/validación** de origen y destino (Google Places si vino texto).
2. **Candidatos por modo**: Google Directions para caminata/auto; grafo propio para teleférico y PumaKatari construido desde `transport_lines` + `transport_stops` (estaciones como nodos, tramos con tiempo estimado).
3. **Composición multimodal**: combina tramos caminar → estación → línea → transbordo → destino. Reglas simples de conexión por cercanía de paradas (radio de 400 m) — suficiente y explicable para la hackatón.
4. **Filtro de incidentes** (HU-1.5): pide a `incidents` los activos, descarta/penaliza tramos de superficie que crucen `affected_area` o pasen a < 150 m del punto; el teleférico no se penaliza.
5. **Scoring**: cada opción obtiene tiempo, costo (suma de tarifas de `transport_lines` + taxi por distancia) y seguridad (cruce con `risk_zones` según hora). El `priority` del request solo cambia el **orden**, siempre se devuelven las 3 métricas (HU-1.3 ordena en el cliente sin recalcular).
6. **Accesibilidad** (HU-5.3): con `reduced_mobility` se filtran paradas `is_accessible = false` y se penaliza caminata/pendiente.

Servicios separados, cada uno con un objetivo: `GeocodingService`, `SurfaceRoutesService` (Google), `NetworkGraphService` (teleférico/Puma), `RouteComposerService`, `IncidentFilterService`, `RouteScoringService`, `RecommendationService` (orquesta).

### Catálogo de transporte

| Método | Ruta | Descripción |
|---|---|---|
| `GET` | `/transports/lines` | Todas las líneas con tipo, color, tarifa, horario |
| `GET` | `/transports/lines/:id/stops` | Paradas/estaciones ordenadas de una línea |

Los datos se cargan con **seeds** (scripts SQL/TS): las 11 líneas reales de teleférico con sus estaciones y tarifas, rutas PumaKatari y zonas de radiotaxi armadas desde información pública.

## Flujo 2 — Viaje en curso, colaboración, comunidad y Puntos Chass

### Viajes y compartir ubicación

| Método | Ruta | HU | Descripción |
|---|---|---|---|
| `POST` | `/trips` | HU-2.1 | Inicia viaje con la opción elegida (`route_snapshot`) |
| `PATCH` | `/trips/:id/finish` | HU-2.1 | Cierra el viaje |
| `GET` | `/users/me/trips?page&pageSize` | HU-2.8 | Historial de viajes del usuario, más reciente primero |
| `POST` | `/collaboration/shares` | HU-2.2 | Empieza a compartir ubicación: `{ tripId, lineId }`. Un share activo = "persona activa en la ruta" para la comunidad |
| `POST` | `/collaboration/shares/:id/pings` | HU-2.2 | Ping periódico `{ lat, lng, recordedAt }` (cada ~15 s) |
| `PATCH` | `/collaboration/shares/:id/stop` | HU-2.2 | Termina de compartir → calcula y acredita puntos |
| `GET` | `/users/me/ayni` | HU-2.4 | Saldo + historial paginado de `ayni_transactions` |

> `POST /collaboration/vehicle-queries` (estimación automática agregando pings) queda **deprecado para el front**: la consulta de transporte evolucionó a preguntas usuario a usuario (módulo `community`). El endpoint se mantiene funcionando como respaldo.

### Comunidad — SOS usuario a usuario (módulo `community`)

Quien espera un transporte pregunta a las personas activas en esa ruta; quien responde gana los puntos que gastó el que preguntó.

| Método | Ruta | HU | Descripción |
|---|---|---|---|
| `GET` | `/community/lines/:lineId/activity` | HU-2.3 | `{ "activePeople": n }` — cuántos shares activos hay en la línea (nunca quiénes ni dónde) |
| `POST` | `/community/questions` | HU-2.3 | `{ lineId, kind, content? }` con `kind: availability \| arrival_time \| seats`. Descuenta `AYNI_QUESTION_COST` puntos y crea la pregunta con vencimiento `AYNI_QUESTION_TIMEOUT_MINUTES`. Si no hay personas activas en la línea: `409 NO_ACTIVE_COLLABORATORS` y **no se cobra** |
| `GET` | `/community/questions/mine` | HU-2.3 | Mis preguntas recientes con sus respuestas (la app hace polling mientras espera) |
| `GET` | `/community/questions/pending` | HU-2.7 | Preguntas abiertas de las líneas donde **yo** tengo un share activo (alimenta el pop-up "ayudar a esta persona"); excluye las mías |
| `POST` | `/community/questions/:id/answers` | HU-2.7 | `{ content }` → responde la pregunta, la marca `answered` y acredita los puntos al que responde. Devuelve `{ answer, pointsAwarded, newBalance }` |

Pregunta (`data` de `POST /community/questions`):

```json
{
  "id": "…",
  "lineId": "…",
  "kind": "arrival_time",
  "content": "¿Está muy lleno a esta hora?",
  "pointsCost": 5,
  "status": "open",
  "createdAt": "…",
  "expiresAt": "…",
  "answers": []
}
```

Reglas de negocio (`community/services/CommunityQuestionsService`):

- Crear la pregunta y descontar puntos es **atómico** (RPC `create_community_question`); responder, marcar `answered` y acreditar puntos también (RPC `answer_community_question`).
- Solo puede responder quien tiene un **share activo en esa línea**; nadie responde su propia pregunta (`CANNOT_ANSWER_OWN_QUESTION`).
- La primera respuesta cierra la pregunta y se lleva los puntos; una segunda llega tarde: `409 QUESTION_ALREADY_ANSWERED`.
- Si nadie responde antes de `expires_at`, un job (`@nestjs/schedule`, cada minuto) marca la pregunta `expired` y **reembolsa los puntos** al que preguntó (RPC `expire_community_questions`, movimiento `question_refunded`). Honestidad ante todo: la app informa "nadie respondió, te devolvimos tus puntos".
- La identidad del que responde no se expone al que pregunta (solo el contenido de la respuesta).

### Reglas de negocio de Puntos Chass (`collaboration/services/AyniPointsService`)

- Ganancia por compartir: `puntos = minutos_compartidos * AYNI_RATE_PER_MINUTE` (tope `AYNI_MAXIMUM_POINTS_PER_SHARE`).
- Ganancia por responder una pregunta: los `points_cost` de la pregunta (movimiento `answered_question`).
- Ganancia por reporte verificado: `AYNI_VERIFIED_REPORT_REWARD` cuando un incidente reportado pasa a `active` (movimiento `verified_report`, ver Flujo 4).
- Costo de preguntar: `AYNI_QUESTION_COST` (movimiento `asked_question`); se reembolsa si la pregunta expira sin respuesta.
- Acreditación y débito siempre pasan por `ayni_transactions` dentro de una transacción SQL (RPC `adjust_ayni_points`); `profiles.ayni_points` es el saldo materializado.

## Flujo 3 — Modo urgencia

| Método | Ruta | HU | Descripción |
|---|---|---|---|
| `POST` | `/emergency/route` | HU-3.2 | `{ origin }` → hospital con menor **tiempo real** de llegada considerando incidentes; incluye alternativas |
| `GET` | `/emergency/contacts` | HU-3.3 | Lista fija: 911, 165, 160 (ambulancias), Red 114 GAMLP |
| `GET` | `/emergency/facilities/near?lat&lng&radius` | HU-3.4 | Hospitales y puntos policiales cercanos a la ruta |

`/emergency/route` reutiliza el motor del Flujo 1 con `priority=time` forzado, evaluando los N hospitales más cercanos de `health_facilities` y devolviendo el de menor duración. `health_facilities` se llena con seed de hospitales y módulos policiales reales de La Paz.

## Flujo 4 — Incidentes y verificación de vías

| Método | Ruta | HU | Descripción |
|---|---|---|---|
| `POST` | `/incidents` | HU-4.1 | Crea reporte ciudadano (estado `pending`); foto ya subida a Storage, llega la URL |
| `POST` | `/incidents/:id/votes` | HU-4.2 | `{ vote: "confirm" | "deny" }`; único por usuario |
| `GET` | `/incidents/active?bbox=` | HU-4.4 | Incidentes `active` + cierres oficiales dentro del viewport |
| `GET` | `/incidents/pending/near?lat&lng` | HU-4.2 | Pendientes cercanos para pedir confirmación |
| `POST` | `/incidents/official` | HU-4.3 | Solo rol `government`: crea cierre oficial (`source=official`, activo de inmediato) |

### Reglas de verificación (`incidents/services/IncidentVerificationService`)

- `confirmations >= UMBRAL_CONFIRMACION` (config, ej. 3) → `status = active`.
- `denials >= UMBRAL_CIERRE` con proporción mayor a confirmaciones recientes → `status = resolved`.
- Duplicados: un `POST /incidents` a < 100 m de un incidente `pending|active` del mismo tipo se convierte automáticamente en confirmación.
- **Puntos por reporte verificado (HU-4.1):** cuando el voto que supera el umbral pasa el incidente de `pending` a `active`, el autor del reporte gana `AYNI_VERIFIED_REPORT_REWARD` Puntos Chass (movimiento `verified_report` con el incidente como referencia). Un índice único parcial sobre `ayni_transactions(reference_id) where reason = 'verified_report'` garantiza que nunca se acredite dos veces por el mismo incidente.
- Expiración: job programado (`@nestjs/schedule`) que resuelve incidentes pasados de `expires_at` (default: bloqueos 12 h, refacciones 7 días).
- El tráfico normal (HU-4.5) **no pasa por el backend**: la capa de tráfico la pinta Google Maps en el cliente.

## Flujo 5 — Agente IA y accesibilidad

El backend NestJS es **proxy y contexto**; la inteligencia vive en los servicios Python en Azure.

| Método | Ruta | HU | Descripción |
|---|---|---|---|
| `POST` | `/assistant/chat` | HU-5.1, 5.4 | `{ message, tripId?, location? }` → respuesta del agente |
| `POST` | `/assistant/voice-route` | HU-5.1 | Texto transcrito del destino → confirma y devuelve recomendación en formato hablado |

- `assistant/services/AssistantContextService` arma el contexto que se manda al servicio Python: viaje activo, incidentes de la zona, `shared_experiences` de la misma zona/franja horaria, líneas disponibles a esa hora.
- El servicio Python (FastAPI + LLM) responde texto listo para TTS; el speech-to-text y text-to-speech se resuelven en el cliente o con Azure Speech (ver doc de Azure).
- La respuesta marca `isCommunityEstimate: true` cuando se basa en experiencias de usuarios (HU-5.4).

## Flujo 6 — Capa de costos

No tiene endpoints propios: **vive dentro del motor de recomendación** (Flujo 1).

- `RouteScoringService` calcula `costBs` por tramo desde `transport_lines.fare_bs`; taxi = tarifa base por zona + Bs/km (tabla de config).
- `priority=cost` ordena por `totalCostBs`; `priority=safety` activa el reemplazo de tramos a pie por taxi en zonas de riesgo (HU-6.3, HU-7.2).

## Flujo 7 — Zonas de riesgo

| Método | Ruta | HU | Descripción |
|---|---|---|---|
| `GET` | `/safety/risk-zones?activeAt=` | HU-7.1 | Zonas cuyo rango horario incluye la hora dada (default: ahora) |

- Seed de zonas de riesgo con polígonos y franjas horarias (datos preparados para el demo).
- El motor de rutas consulta este módulo para `safetyScore` y para el reemplazo caminar→taxi.

## Flujo 8 — Vista de gobierno

| Método | Ruta | HU | Descripción |
|---|---|---|---|
| `GET` | `/government/congestion/summary?from&to` | HU-8.2 | Agregado: incidentes por tipo, por zona, serie temporal |
| `GET` | `/government/incidents?status&kind&from&to` | HU-8.2 | Listado completo con filtros (incluye `pending` y `rejected`) |

Ambos protegidos con `@Roles('government')`. Las cuentas de gobierno del demo se crean por seed.

## Flujo 9 — Denuncias de transporte

| Método | Ruta | HU | Descripción |
|---|---|---|---|
| `POST` | `/complaints` | HU-9.1 | Registra la denuncia (nace `submitted`) |
| `GET` | `/complaints/mine` | HU-9.1 | Mis denuncias, más reciente primero |

Request de `POST /complaints`:

```json
{
  "vehicleIdentifier": "1234-ABC",
  "transportKind": "cable_car",
  "lineId": "…",
  "stopId": "…",
  "complaint": "El operador no dejó subir una silla de ruedas"
}
```

- `vehicleIdentifier` es la placa o número del vehículo (texto libre, obligatorio salvo que venga `lineId`).
- `lineId`/`stopId` son opcionales y se validan contra el catálogo `transports` (la parada debe pertenecer a la línea): teleférico → línea + estación; PumaKatari → ruta + parada.
- `GET /government/complaints` (revisión por gobierno, HU-9.2) queda ⚪ futuro: no se implementa para la hackatón.

---

## Transversales

### Configuración (variables de entorno)

```
SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
GOOGLE_MAPS_API_KEY
AI_AGENT_BASE_URL, AI_AGENT_API_KEY
AYNI_RATE_PER_MINUTE, AYNI_QUERY_COST, AYNI_QUESTION_COST,
AYNI_QUESTION_TIMEOUT_MINUTES, AYNI_VERIFIED_REPORT_REWARD,
INCIDENT_CONFIRM_THRESHOLD
PORT, CORS_ORIGINS
```

### Seeds (carpeta `seeds/`)
1. Líneas y estaciones de teleférico (11 líneas reales, tarifas, horario 05:00–23:00).
2. Rutas PumaKatari principales (datos públicos, realistas).
3. Zonas de radiotaxi con tarifas.
4. Hospitales y módulos policiales de La Paz.
5. Zonas de riesgo con franjas horarias (demo).
6. Incidentes y cierres oficiales de ejemplo (demo).
7. Cuentas demo: ciudadano, colaborador con puntos, gobierno.

### Orden de desarrollo sugerido (backend primero)

1. Esqueleto NestJS + guard Supabase + módulo `users` (Flujo 0).
2. Catálogo `transports` + seeds de teleférico/Puma.
3. Motor `routing` con Google Directions + grafo propio (Flujo 1 sin incidentes).
4. Módulo `incidents` + integración con el motor (HU-1.5).
5. `collaboration` + Puntos Chass (Flujo 2).
6. `emergency`, `safety`, `government` (rápidos: reutilizan el motor y son CRUD/agregaciones).
7. `assistant` (proxy al servicio Python) al final.
