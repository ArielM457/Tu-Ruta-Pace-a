-- Upgrade: contrato completo de denuncias (tipo, ruta libre, foto, estados).
-- Ejecutar una vez en el SQL Editor de Supabase sobre una base que ya tiene
-- 00-schema.sql y 05-community-complaints-upgrade.sql. Es idempotente.

alter table public.complaints
  add column if not exists complaint_type text not null default 'other';

alter table public.complaints
  add column if not exists route_label text;

alter table public.complaints
  add column if not exists photo_url text;

update public.complaints
  set status = 'in_review'
  where status = 'submitted';

alter table public.complaints
  alter column status set default 'in_review';
