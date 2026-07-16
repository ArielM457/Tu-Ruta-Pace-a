# Avances — Deploy

Registro del despliegue del proyecto: recursos de Azure creados, URLs de los ambientes, pipeline y pasos ejecutados. El plan de recursos está en [04-recursos-azure.md](../../04-recursos-azure.md).

Estado actual: **sin deploy todavía**. El backend corre local (`npm run start:dev` en `backend/`).

Pendientes:
1. Crear el grupo de recursos `rg-ayni-ruta`.
2. App Service (Linux, Node 20) para el backend + variables de entorno de producción.
3. Application Insights conectado.
4. Conectar el repositorio para deploy continuo (GitHub Actions).
