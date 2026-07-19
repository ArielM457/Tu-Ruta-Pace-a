-- Upgrade: ranking semanal y feed de actividad de la comunidad (T6.1).
-- Ejecutar una vez en el SQL Editor de Supabase. Es idempotente
-- (create or replace function).

create or replace function public.community_weekly_ranking()
returns table (
  user_id uuid,
  display_name text,
  points bigint,
  rnk bigint
)
language sql
stable
security definer
set search_path = public
as $$
  select
    t.user_id,
    coalesce(p.display_name, 'Colaborador') as display_name,
    sum(t.amount) as points,
    rank() over (order by sum(t.amount) desc) as rnk
  from public.ayni_transactions t
  join public.profiles p on p.id = t.user_id
  where t.created_at >= date_trunc('week', now())
  group by t.user_id, p.display_name
  order by points desc;
$$;

create or replace function public.community_feed(p_limit integer default 20)
returns table (
  id uuid,
  user_id uuid,
  display_name text,
  reason text,
  amount integer,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public
as $$
  select
    t.id,
    t.user_id,
    coalesce(p.display_name, 'Colaborador') as display_name,
    t.reason,
    t.amount,
    t.created_at
  from public.ayni_transactions t
  join public.profiles p on p.id = t.user_id
  where t.reason in ('verified_report', 'confirmed_incident', 'answered_question')
    and t.amount > 0
  order by t.created_at desc
  limit p_limit;
$$;
