-- Upgrade: comunidad (SOS usuario a usuario), denuncias y puntos por reporte verificado.
-- Ejecutar una vez en el SQL Editor de Supabase sobre una base que ya tiene 00-schema.sql.
-- Es idempotente: re-ejecutarlo no duplica nada. (Todo esto también vive en 00-schema.sql.)

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

create index if not exists idx_community_questions_line_status on public.community_questions(line_id, status);
create index if not exists idx_community_questions_asker on public.community_questions(asker_id, created_at);
create index if not exists idx_community_answers_question on public.community_answers(question_id);
create index if not exists idx_complaints_user on public.complaints(user_id, created_at);
create unique index if not exists uq_ayni_verified_report
  on public.ayni_transactions(reference_id) where reason = 'verified_report';

alter table public.community_questions enable row level security;
alter table public.community_answers enable row level security;
alter table public.complaints enable row level security;

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
