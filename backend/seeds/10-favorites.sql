-- Upgrade: rutas favoritas del perfil (T7.1).
-- Ejecutar una vez en el SQL Editor de Supabase. Es idempotente.

create table if not exists public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  lat double precision not null,
  lng double precision not null,
  created_at timestamptz not null default now()
);

create index if not exists idx_favorites_user on public.favorites(user_id, created_at);

alter table public.favorites enable row level security;
