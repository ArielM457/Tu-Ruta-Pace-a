# Seeds de Ayni Ruta

Scripts SQL para preparar la base de datos en Supabase. Se ejecutan en el **SQL Editor** de Supabase (Dashboard → SQL Editor → New query), **en este orden**:

| Orden | Archivo | Qué crea |
|---|---|---|
| 1 | `00-schema.sql` | Todas las tablas, índices, RLS, el trigger que crea el perfil al registrarse y las funciones RPC (`adjust_ayni_points`, `register_incident_vote`) |
| 2 | `01-transport-network.sql` | Las 10 líneas operativas del teleférico con sus estaciones, 3 rutas PumaKatari y 3 zonas de radiotaxi (coordenadas aproximadas de La Paz) |
| 3 | `02-health-facilities.sql` | Hospitales y puntos policiales de La Paz/El Alto |
| 4 | `03-risk-zones.sql` | Zonas de riesgo con franjas horarias (datos preparados para el demo) |
| 5 | `04-demo-data.sql` | Incidentes activos/pendientes y experiencias comunitarias de ejemplo |

Todos los scripts son idempotentes o seguros de re-ejecutar excepto `02`–`04`, que insertan filas nuevas cada vez (ejecutarlos una sola vez).

## Cuentas demo

Los usuarios se crean vía Supabase Auth (registro desde la app o Dashboard → Authentication → Add user). El trigger `on_auth_user_created` crea el perfil automáticamente.

Para dar rol de gobierno a una cuenta:

```sql
update public.profiles set role = 'government' where id = '<uuid-del-usuario>';
```

Para regalar puntos Ayni iniciales a una cuenta demo:

```sql
select public.adjust_ayni_points('<uuid-del-usuario>', 50, 'bonus', null);
```
