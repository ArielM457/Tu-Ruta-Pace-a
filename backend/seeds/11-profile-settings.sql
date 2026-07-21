-- Upgrade: teléfono opcional y toggles de configuración del perfil (T7.3).
-- Ejecutar una vez en el SQL Editor de Supabase. Es idempotente.

alter table public.profiles
  add column if not exists phone text;

alter table public.profiles
  add column if not exists route_alerts_enabled boolean not null default true;

alter table public.profiles
  add column if not exists share_location_with_family boolean not null default false;
