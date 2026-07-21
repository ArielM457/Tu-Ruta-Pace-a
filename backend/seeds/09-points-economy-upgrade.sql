-- Upgrade: desacopla el costo de preguntar (−50) de la recompensa por
-- responder (+5) — antes eran el mismo número. Ejecutar una vez en el
-- SQL Editor de Supabase. Es idempotente.

drop function if exists public.answer_community_question(uuid, uuid, text);

create or replace function public.answer_community_question(
  p_question_id uuid,
  p_responder_id uuid,
  p_content text,
  p_reward_amount integer
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
  values (p_question_id, p_responder_id, p_content, p_reward_amount)
  returning id into v_answer_id;
  update public.community_questions
  set status = 'answered', answered_at = now()
  where id = p_question_id;
  update public.profiles
  set ayni_points = ayni_points + p_reward_amount
  where id = p_responder_id;
  insert into public.ayni_transactions (user_id, amount, reason, reference_id)
  values (p_responder_id, p_reward_amount, 'answered_question', v_answer_id);
  return query select * from public.community_answers where id = v_answer_id;
end;
$$;
