# Avance del Backend — Ayni Ruta

> Última actualización: 16 de julio de 2026
> Estado: **API completa implementada, compilando y verificada por consola.** Falta conectar credenciales reales (Supabase, Google, Azure Foundry) y el deploy.

## Qué está construido

El backend NestJS está **100% implementado** según el diseño de [02-backend.md](../../02-backend.md): los 10 módulos de dominio, el motor de recomendación multimodal, el sistema de puntos Ayni, la verificación de incidentes, el modo urgencia, las zonas de riesgo, el proxy al agente IA y la vista de gobierno.

| Módulo | Flujo que cubre | Estado |
|---|---|---|
| `users` | Flujo 0 — perfil y preferencias | ✅ Completo |
| `transports` | Catálogo teleférico/PumaKatari/radiotaxis | ✅ Completo (con seeds) |
| `routing` | Flujo 1 y 6 — motor multimodal + costos | ✅ Completo |
| `trips` | Flujo 2 — viajes | ✅ Completo |
| `collaboration` | Flujo 2 — ubicación colaborativa + puntos Ayni | ✅ Completo |
| `emergency` | Flujo 3 — modo urgencia | ✅ Completo |
| `incidents` | Flujo 4 — reportes y verificación de vías | ✅ Completo |
| `safety` | Flujo 7 — zonas de riesgo | ✅ Completo |
| `assistant` | Flujo 5 — agente IA (Azure AI Foundry) | ✅ Completo (necesita credenciales Foundry) |
| `government` | Flujo 8 — monitoreo de congestión | ✅ Completo |

## Endpoints implementados

Base: `http://localhost:3000/api/v1` — todas las respuestas usan el sobre `{ "data": ..., "error": null }` / `{ "data": null, "error": { "code", "message" } }`. Salvo `/health`, todo requiere `Authorization: Bearer <access_token de Supabase>`.

### Salud
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/health` | Health check público |

### Usuarios (Flujo 0)
| Método | Ruta | Descripción |
|---|---|---|
| POST | `/users/me/bootstrap` | Crea el perfil tras el primer login (idempotente). Body opcional: `{ displayName }` |
| GET | `/users/me` | Perfil: nombre, rol, accesibilidad, prioridad por defecto, puntos Ayni |
| PATCH | `/users/me` | Actualiza `displayName`, `accessibilityProfile` (`none/visual/reduced_mobility`), `defaultPriority` (`time/cost/safety`) |

### Transporte (catálogo)
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/transports/lines` | Líneas activas: teleférico (10), PumaKatari (3), zonas radiotaxi (3), con tarifa y horario |
| GET | `/transports/lines/:id/stops` | Estaciones/paradas ordenadas de una línea |

### Motor de rutas (Flujos 1 y 6)
| Método | Ruta | Descripción |
|---|---|---|
| POST | `/routing/recommendations` | Body: `{ origin: {lat,lng}, destination: {lat,lng}, priority?, accessibility? }`. Devuelve hasta 4 opciones multimodales con tramos, tiempo, costo Bs, `safetyScore` y `avoidsIncidents` |

El motor: combina caminata + teleférico/PumaKatari (directo o con 1 transbordo a ≤400 m) + taxi + minibús; penaliza tramos de superficie a <150 m de incidentes activos (el teleférico nunca se penaliza); con prioridad `safety` reemplaza caminatas en zona de riesgo por taxi; sin API key de Google usa estimaciones locales (haversine × factor vial).

### Viajes y colaboración Ayni (Flujo 2)
| Método | Ruta | Descripción |
|---|---|---|
| POST | `/trips` | Inicia viaje con `{ routeSnapshot }` (cancela viajes activos previos) |
| PATCH | `/trips/:id/finish` | Finaliza el viaje |
| POST | `/collaboration/shares` | Empieza a compartir ubicación: `{ tripId, lineId }` |
| POST | `/collaboration/shares/:id/pings` | Ping periódico `{ lat, lng }` (cada ~15 s). Responde 204 |
| PATCH | `/collaboration/shares/:id/stop` | Deja de compartir → acredita puntos (1 pto/min, tope 60) y devuelve `newBalance` |
| POST | `/collaboration/vehicle-queries` | `{ lineId, stopId }` → posición agregada del transporte + ETA. Cuesta 5 puntos; si no hay colaboradores: `{ available: false }` y **no cobra** |
| GET | `/users/me/ayni` | Saldo + historial paginado (`page`, `pageSize`) |

### Modo urgencia (Flujo 3)
| Método | Ruta | Descripción |
|---|---|---|
| POST | `/emergency/route` | `{ origin }` → hospital con menor tiempo real (evalúa los 4 más cercanos, penaliza rutas con incidentes) + alternativas |
| GET | `/emergency/contacts` | 911, 165, 160 (ambulancias), Red 114 GAMLP |
| GET | `/emergency/facilities/near?lat&lng&radius&kind` | Hospitales y puntos policiales cercanos |

### Incidentes (Flujo 4)
| Método | Ruta | Descripción |
|---|---|---|
| POST | `/incidents` | Reporte ciudadano `{ kind: blockade/protest/roadwork, position, description, photoUrl? }`. Nace `pending`; si hay duplicado a <100 m se convierte en confirmación |
| POST | `/incidents/:id/votes` | `{ vote: confirm/deny }` (único por usuario). Con 3 confirmaciones pasa a `active`; con 3 "ya no está" se resuelve |
| GET | `/incidents/active?bbox=` | Incidentes activos + cierres oficiales (filtro por viewport opcional) |
| GET | `/incidents/pending/near?lat&lng&radius` | Pendientes cercanos para pedir confirmación |
| POST | `/incidents/official` | **Solo rol gobierno.** Cierre oficial, activo de inmediato |

Job programado: cada hora expira incidentes vencidos (bloqueos 12 h, refacciones 7 días).

### Zonas de riesgo (Flujo 7)
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/safety/risk-zones?activeAt=` | Zonas cuya franja horaria está activa (maneja franjas que cruzan medianoche) |

### Asistente IA (Flujo 5) — Azure AI Foundry
| Método | Ruta | Descripción |
|---|---|---|
| POST | `/assistant/chat` | `{ message, tripId?, location? }` → el backend arma contexto (viaje activo, incidentes cercanos, líneas en servicio, experiencias comunitarias) y consulta al agente Foundry. Devuelve `{ reply, isCommunityEstimate }` |
| POST | `/assistant/voice-route` | `{ transcript, location? }` → `{ confirmedDestination, spokenReply }` para el flujo de voz |

Sin credenciales Foundry responde 503 `AI_AGENT_NOT_CONFIGURED` (la app puede manejarlo).

### Vista gobierno (Flujo 8) — solo rol `government`
| Método | Ruta | Descripción |
|---|---|---|
| GET | `/government/congestion/summary?from&to` | Agregados: total, por tipo/estado/fuente, serie diaria |
| GET | `/government/incidents?status&kind&from&to` | Listado completo con filtros (incluye pendientes y rechazados) |

## Códigos de error del dominio

`MISSING_TOKEN`, `INVALID_TOKEN`, `FORBIDDEN_ROLE`, `PROFILE_NOT_FOUND`, `LINE_NOT_FOUND`, `STOP_NOT_FOUND`, `TRIP_NOT_FOUND`, `TRIP_NOT_ACTIVE`, `SHARE_NOT_FOUND`, `SHARE_ALREADY_ENDED`, `INSUFFICIENT_AYNI_POINTS`, `ALREADY_VOTED`, `INCIDENT_NOT_FOUND`, `NO_HOSPITALS_AVAILABLE`, `AI_AGENT_NOT_CONFIGURED`, `AI_AGENT_UNAVAILABLE`, `DATABASE_ERROR`, `INTERNAL_ERROR`.

## Base de datos (Supabase)

- Schema completo en [backend/seeds/00-schema.sql](../../../backend/seeds/00-schema.sql): 13 tablas, índices, RLS, trigger que crea el perfil al registrarse, y 2 funciones RPC atómicas (`adjust_ayni_points`, `register_incident_vote`).
- Seeds de datos: red de transporte (01), hospitales/policía (02), zonas de riesgo (03), incidentes y experiencias demo (04). Guía en [backend/seeds/README.md](../../../backend/seeds/README.md).

## Verificación realizada (por consola, sin tests unitarios)

- `npm run build` ✅ y `npm run lint` ✅.
- Servidor arranca y mapea todas las rutas ✅.
- Smoke tests por consola ([backend/scripts/smoke-tests.ps1](../../../backend/scripts/smoke-tests.ps1)): health ✅, guard sin token ✅, rechazo en rutas protegidas ✅. La batería autenticada completa (20+ pasos) queda lista para correr apenas se llene el `.env`.

## Pendientes

1. Llenar `.env`: credenciales de Supabase (URL, service role key, JWT secret) → corre seeds → smoke tests completos.
2. API key de Google Maps (Directions + Places) — sin ella el motor funciona con estimaciones locales.
3. Credenciales del agente de Azure AI Foundry (`AZURE_FOUNDRY_ENDPOINT`, `AZURE_FOUNDRY_API_KEY`, `AZURE_FOUNDRY_AGENT_ID`) y crear el agente en Foundry.
4. Deploy en Azure App Service (ver carpeta [deploy](../deploy/)).
5. Ingesta de cierres oficiales desde fuentes GAMLP (hoy entran por el endpoint de gobierno o seeds).
