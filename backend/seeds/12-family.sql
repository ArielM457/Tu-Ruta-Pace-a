-- Upgrade: cuentas familiares (T8.1).
-- Ejecutar una vez en el SQL Editor de Supabase. Es idempotente.

create table if not exists public.family_groups (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  owner_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);

create table if not exists public.family_members (
  id uuid primary key default gen_random_uuid(),
  group_id uuid not null references public.family_groups(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  relationship_label text,
  invited_email text,
  invite_code text not null,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  unique (group_id, user_id)
);

create unique index if not exists uq_family_members_invite_code
  on public.family_members(invite_code);
create index if not exists idx_family_members_group on public.family_members(group_id);
create index if not exists idx_family_members_user on public.family_members(user_id);

alter table public.family_groups enable row level security;
alter table public.family_members enable row level security;
