# Ayni Ruta — Backend

API REST en NestJS para la app de movilidad multimodal de La Paz. Diseño completo en [docs/02-backend.md](../docs/02-backend.md).

## Requisitos

- Node.js 20+
- Un proyecto de Supabase (BD, Auth y Storage)
- API key de Google Maps Platform (Directions) — opcional en desarrollo: sin key el motor usa estimaciones locales

## Puesta en marcha

1. **Base de datos**: ejecuta los scripts de [`seeds/`](seeds/README.md) en el SQL Editor de Supabase, en orden.
2. **Variables de entorno**: completa `.env` (ya existe con todas las claves vacías):

| Variable | De dónde sale |
|---|---|
| `SUPABASE_URL` | Supabase → Settings → API → Project URL |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase → Settings → API → service_role key |
| `SUPABASE_JWT_SECRET` | Supabase → Settings → API → JWT Secret |
| `GOOGLE_MAPS_API_KEY` | Google Cloud Console (Directions API habilitada) |
| `AZURE_FOUNDRY_ENDPOINT` | Azure AI Foundry → tu proyecto → Overview → Endpoint del proyecto (ej. `https://<recurso>.services.ai.azure.com/api/projects/<proyecto>`) |
| `AZURE_FOUNDRY_API_KEY` | Azure AI Foundry → proyecto → claves del recurso (o Azure Portal → recurso AI Foundry → Keys and Endpoint) |
| `AZURE_FOUNDRY_AGENT_ID` | Azure AI Foundry → Agents → tu agente → ID (empieza con `asst_`) |
| `AZURE_FOUNDRY_API_VERSION` | Versión de la API del Agent Service (default `2025-05-01`) |
| `AYNI_*`, `INCIDENT_*` | Parámetros de negocio, ya tienen valores por defecto |

3. **Instalar y correr**:

```bash
npm install
npm run start:dev
```

La API queda en `http://localhost:3000/api/v1` (health check público: `GET /api/v1/health`).

## Autenticación

El registro/login lo hace la app móvil directo contra Supabase Auth. Cada request a esta API lleva `Authorization: Bearer <access_token de Supabase>`. Tras el primer login, la app llama `POST /users/me/bootstrap`.

## Endpoints

| Módulo | Rutas |
|---|---|
| Salud | `GET /health` (público) |
| Usuarios | `POST /users/me/bootstrap`, `GET /users/me`, `PATCH /users/me` |
| Transporte | `GET /transports/lines`, `GET /transports/lines/:id/stops` |
| Rutas | `POST /routing/recommendations` |
| Viajes | `POST /trips`, `PATCH /trips/:id/finish` |
| Colaboración | `POST /collaboration/shares`, `POST /collaboration/shares/:id/pings`, `PATCH /collaboration/shares/:id/stop`, `POST /collaboration/vehicle-queries`, `GET /users/me/ayni` |
| Urgencia | `POST /emergency/route`, `GET /emergency/contacts`, `GET /emergency/facilities/near` |
| Incidentes | `POST /incidents`, `POST /incidents/:id/votes`, `GET /incidents/active`, `GET /incidents/pending/near`, `POST /incidents/official` (rol gobierno) |
| Seguridad | `GET /safety/risk-zones` |
| Asistente | `POST /assistant/chat`, `POST /assistant/voice-route` |
| Gobierno | `GET /government/congestion/summary`, `GET /government/incidents` (rol gobierno) |

Todas las respuestas usan el sobre `{ "data": ..., "error": null }` / `{ "data": null, "error": { "code", "message" } }`.

## Scripts

```bash
npm run start:dev   # desarrollo con recarga
npm run build       # compilar
npm run test        # tests unitarios
npm run lint        # eslint
```

## Notas de implementación

- Las posiciones se guardan como columnas `lat`/`lng` y las distancias se calculan con haversine en la aplicación (suficiente a escala urbana y sin depender de PostGIS vía RPC).
- Los movimientos de puntos Ayni y los votos de incidentes son atómicos vía funciones RPC en Postgres (`adjust_ayni_points`, `register_incident_vote`).
- Sin `GOOGLE_MAPS_API_KEY`, tiempos y distancias se estiman localmente (distancia haversine con factor vial) para poder desarrollar sin credenciales.
- El asistente usa un **agente de Azure AI Foundry** (Agent Service): el backend crea un thread+run por consulta, espera a que complete y lee la respuesta. Sin las variables `AZURE_FOUNDRY_*`, `/assistant/*` responde 503 `AI_AGENT_NOT_CONFIGURED`. Si tu proyecto Foundry solo acepta Entra ID (y no API key), avísanos para cambiar la autenticación a tokens.
- Verificación por consola: `scripts/smoke-tests.ps1` corre la batería completa de endpoints contra el servidor levantado (no hay tests unitarios en este proyecto, por decisión del equipo).
