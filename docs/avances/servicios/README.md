# Avances — Servicios externos

Estado de cada servicio del que depende el proyecto: credenciales conseguidas, configuración hecha y pendientes.

| Servicio | Para qué | Estado |
|---|---|---|
| Supabase (BD + Auth + Storage) | Base de datos, login, fotos de reportes | ⏳ Falta crear el proyecto y llenar `.env`; el schema y seeds ya están listos en `backend/seeds/` |
| Google Maps Platform (Directions + Places) | Tiempos/distancias reales y autocompletado | ⏳ Falta crear la API key (guía en `backend/README.md`) |
| Azure AI Foundry (Agent Service) | Agente IA del asistente | ⏳ Falta crear el proyecto, el agente y llenar `AZURE_FOUNDRY_*` en `.env` |
| Azure App Service | Hosting del backend | ⏳ Pendiente (ver carpeta deploy) |

Actualizar esta tabla cada vez que un servicio quede conectado.
