create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  role text not null default 'citizen',
  accessibility_profile text not null default 'none',
  default_priority text not null default 'time',
  ayni_points integer not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.transport_lines (
  id uuid primary key default gen_random_uuid(),
  kind text not null,
  name text not null,
  color text,
  fare_bs numeric not null default 0,
  service_start time,
  service_end time,
  is_active boolean not null default true
);

create table if not exists public.transport_stops (
  id uuid primary key default gen_random_uuid(),
  line_id uuid not null references public.transport_lines(id) on delete cascade,
  name text not null,
  lat double precision not null,
  lng double precision not null,
  sequence integer not null,
  is_accessible boolean not null default true
);

create table if not exists public.route_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  origin_lat double precision not null,
  origin_lng double precision not null,
  destination_lat double precision not null,
  destination_lng double precision not null,
  priority text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.trips (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  route_snapshot jsonb not null,
  status text not null default 'active',
  started_at timestamptz not null default now(),
  finished_at timestamptz
);

create table if not exists public.location_shares (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  trip_id uuid not null references public.trips(id) on delete cascade,
  line_id uuid not null references public.transport_lines(id) on delete cascade,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  points_awarded integer
);

create table if not exists public.location_pings (
  id bigint generated always as identity primary key,
  share_id uuid not null references public.location_shares(id) on delete cascade,
  lat double precision not null,
  lng double precision not null,
  recorded_at timestamptz not null default now()
);

create table if not exists public.ayni_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  amount integer not null,
  reason text not null,
  reference_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists public.health_facilities (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  kind text not null,
  lat double precision not null,
  lng double precision not null,
  phone text
);

create table if not exists public.incidents (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references auth.users(id) on delete set null,
  kind text not null,
  source text not null default 'citizen',
  status text not null default 'pending',
  lat double precision not null,
  lng double precision not null,
  description text not null,
  photo_url text,
  confirmations integer not null default 0,
  denials integer not null default 0,
  starts_at timestamptz not null default now(),
  expires_at timestamptz not null,
  created_at timestamptz not null default now()
);

create table if not exists public.incident_votes (
  id uuid primary key default gen_random_uuid(),
  incident_id uuid not null references public.incidents(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  vote text not null,
  created_at timestamptz not null default now(),
  unique (incident_id, user_id)
);

create table if not exists public.shared_experiences (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  zone text not null,
  time_slot text not null,
  content text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.community_questions (
  id uuid primary key default gen_random_uuid(),
  asker_id uuid not null references auth.users(id) on delete cascade,
  line_id uuid not null references public.transport_lines(id) on delete cascade,
  kind text not null,
  content text,
  points_cost integer not null,
  status text not null default 'open',
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  answered_at timestamptz
);

create table if not exists public.community_answers (
  id uuid primary key default gen_random_uuid(),
  question_id uuid not null references public.community_questions(id) on delete cascade,
  responder_id uuid not null references auth.users(id) on delete cascade,
  content text not null,
  points_awarded integer not null,
  created_at timestamptz not null default now()
);

create table if not exists public.complaints (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  vehicle_identifier text,
  transport_kind text not null,
  line_id uuid references public.transport_lines(id) on delete set null,
  stop_id uuid references public.transport_stops(id) on delete set null,
  complaint text not null,
  status text not null default 'submitted',
  created_at timestamptz not null default now()
);

create table if not exists public.risk_zones (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  lat double precision not null,
  lng double precision not null,
  radius_meters integer not null default 400,
  risk_start time not null,
  risk_end time not null,
  level text not null default 'medium',
  source text not null default 'seeded'
);

create index if not exists idx_transport_stops_line on public.transport_stops(line_id, sequence);
create index if not exists idx_incidents_status on public.incidents(status);
create index if not exists idx_incidents_created_at on public.incidents(created_at);
create index if not exists idx_location_shares_line_active on public.location_shares(line_id) where ended_at is null;
create index if not exists idx_location_pings_share_time on public.location_pings(share_id, recorded_at);
create index if not exists idx_ayni_transactions_user on public.ayni_transactions(user_id, created_at);
create index if not exists idx_trips_user_status on public.trips(user_id, status);
create index if not exists idx_community_questions_line_status on public.community_questions(line_id, status);
create index if not exists idx_community_questions_asker on public.community_questions(asker_id, created_at);
create index if not exists idx_community_answers_question on public.community_answers(question_id);
create index if not exists idx_complaints_user on public.complaints(user_id, created_at);
create unique index if not exists uq_ayni_verified_report
  on public.ayni_transactions(reference_id) where reason = 'verified_report';

alter table public.profiles enable row level security;
alter table public.transport_lines enable row level security;
alter table public.transport_stops enable row level security;
alter table public.route_requests enable row level security;
alter table public.trips enable row level security;
alter table public.location_shares enable row level security;
alter table public.location_pings enable row level security;
alter table public.ayni_transactions enable row level security;
alter table public.health_facilities enable row level security;
alter table public.incidents enable row level security;
alter table public.incident_votes enable row level security;
alter table public.shared_experiences enable row level security;
alter table public.risk_zones enable row level security;
alter table public.community_questions enable row level security;
alter table public.community_answers enable row level security;
alter table public.complaints enable row level security;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, new.raw_user_meta_data ->> 'display_name')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.adjust_ayni_points(
  p_user_id uuid,
  p_amount integer,
  p_reason text,
  p_reference_id uuid
)
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_new_balance integer;
begin
  update public.profiles
  set ayni_points = ayni_points + p_amount
  where id = p_user_id
  returning ayni_points into v_new_balance;
  if v_new_balance is null then
    raise exception 'PROFILE_NOT_FOUND';
  end if;
  if v_new_balance < 0 then
    raise exception 'INSUFFICIENT_AYNI_POINTS';
  end if;
  if p_amount <> 0 then
    insert into public.ayni_transactions (user_id, amount, reason, reference_id)
    values (p_user_id, p_amount, p_reason, p_reference_id);
  end if;
  return v_new_balance;
end;
$$;

create or replace function public.register_incident_vote(
  p_incident_id uuid,
  p_user_id uuid,
  p_vote text,
  p_confirm_threshold integer,
  p_resolve_threshold integer
)
returns setof public.incidents
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from public.incidents where id = p_incident_id) then
    raise exception 'INCIDENT_NOT_FOUND';
  end if;
  begin
    insert into public.incident_votes (incident_id, user_id, vote)
    values (p_incident_id, p_user_id, p_vote);
  exception when unique_violation then
    raise exception 'ALREADY_VOTED';
  end;
  if p_vote = 'confirm' then
    update public.incidents
    set confirmations = confirmations + 1
    where id = p_incident_id;
  else
    update public.incidents
    set denials = denials + 1
    where id = p_incident_id;
  end if;
  update public.incidents
  set status = 'active'
  where id = p_incident_id
    and status = 'pending'
    and confirmations >= p_confirm_threshold;
  update public.incidents
  set status = 'resolved'
  where id = p_incident_id
    and status in ('pending', 'active')
    and denials >= p_resolve_threshold
    and denials >= confirmations;
  return query select * from public.incidents where id = p_incident_id;
end;
$$;

create or replace function public.create_community_question(
  p_asker_id uuid,
  p_line_id uuid,
  p_kind text,
  p_content text,
  p_points_cost integer,
  p_timeout_minutes integer
)
returns setof public.community_questions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_balance integer;
  v_question_id uuid;
begin
  update public.profiles
  set ayni_points = ayni_points - p_points_cost
  where id = p_asker_id
  returning ayni_points into v_balance;
  if v_balance is null then
    raise exception 'PROFILE_NOT_FOUND';
  end if;
  if v_balance < 0 then
    raise exception 'INSUFFICIENT_AYNI_POINTS';
  end if;
  insert into public.community_questions (asker_id, line_id, kind, content, points_cost, expires_at)
  values (p_asker_id, p_line_id, p_kind, p_content, p_points_cost, now() + make_interval(mins => p_timeout_minutes))
  returning id into v_question_id;
  insert into public.ayni_transactions (user_id, amount, reason, reference_id)
  values (p_asker_id, -p_points_cost, 'asked_question', v_question_id);
  return query select * from public.community_questions where id = v_question_id;
end;
$$;

create or replace function public.answer_community_question(
  p_question_id uuid,
  p_responder_id uuid,
  p_content text
)
returns setof public.community_answers
language plpgsql
security definer
set search_path = public
as $$
declare
  v_question public.community_questions%rowtype;
  v_answer_id uuid;
begin
  select * into v_question
  from public.community_questions
  where id = p_question_id
  for update;
  if not found then
    raise exception 'QUESTION_NOT_FOUND';
  end if;
  if v_question.asker_id = p_responder_id then
    raise exception 'CANNOT_ANSWER_OWN_QUESTION';
  end if;
  if v_question.status = 'answered' then
    raise exception 'QUESTION_ALREADY_ANSWERED';
  end if;
  if v_question.status = 'expired' or v_question.expires_at < now() then
    raise exception 'QUESTION_EXPIRED';
  end if;
  insert into public.community_answers (question_id, responder_id, content, points_awarded)
  values (p_question_id, p_responder_id, p_content, v_question.points_cost)
  returning id into v_answer_id;
  update public.community_questions
  set status = 'answered', answered_at = now()
  where id = p_question_id;
  update public.profiles
  set ayni_points = ayni_points + v_question.points_cost
  where id = p_responder_id;
  insert into public.ayni_transactions (user_id, amount, reason, reference_id)
  values (p_responder_id, v_question.points_cost, 'answered_question', v_answer_id);
  return query select * from public.community_answers where id = v_answer_id;
end;
$$;

create or replace function public.expire_community_questions()
returns integer
language plpgsql
security definer
set search_path = public
as $$
declare
  v_expired_count integer := 0;
  v_question record;
begin
  for v_question in
    select id, asker_id, points_cost
    from public.community_questions
    where status = 'open' and expires_at < now()
    for update skip locked
  loop
    update public.community_questions set status = 'expired' where id = v_question.id;
    update public.profiles set ayni_points = ayni_points + v_question.points_cost where id = v_question.asker_id;
    insert into public.ayni_transactions (user_id, amount, reason, reference_id)
    values (v_question.asker_id, v_question.points_cost, 'question_refunded', v_question.id);
    v_expired_count := v_expired_count + 1;
  end loop;
  return v_expired_count;
end;
$$;
