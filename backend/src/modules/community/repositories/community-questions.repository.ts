import { HttpStatus, Injectable } from '@nestjs/common';
import { DomainException } from '../../../common/exceptions/domain.exception';
import { CommunityQuestionStatus } from '../../../common/types/domain';
import { assertNoDatabaseError } from '../../../integrations/supabase/database-error';
import { SupabaseService } from '../../../integrations/supabase/supabase.service';

export interface CommunityQuestionRecord {
  id: string;
  asker_id: string;
  line_id: string;
  kind: string;
  content: string | null;
  points_cost: number;
  status: string;
  created_at: string;
  expires_at: string;
  answered_at: string | null;
  transport_lines?: { name: string } | null;
}

export interface CommunityAnswerRecord {
  id: string;
  question_id: string;
  responder_id: string;
  content: string;
  points_awarded: number;
  created_at: string;
}

const QUESTION_WITH_LINE_COLUMNS = '*, transport_lines(name)';

@Injectable()
export class CommunityQuestionsRepository {
  constructor(private readonly supabaseService: SupabaseService) {}

  async createQuestion(
    askerId: string,
    lineId: string,
    kind: string,
    content: string | null,
    pointsCost: number,
    timeoutMinutes: number,
  ): Promise<CommunityQuestionRecord> {
    const { data, error } = await this.supabaseService.client.rpc(
      'create_community_question',
      {
        p_asker_id: askerId,
        p_line_id: lineId,
        p_kind: kind,
        p_content: content,
        p_points_cost: pointsCost,
        p_timeout_minutes: timeoutMinutes,
      },
    );
    if (error) {
      if (error.message.includes('INSUFFICIENT_AYNI_POINTS')) {
        throw new DomainException(
          'INSUFFICIENT_AYNI_POINTS',
          'No tienes puntos Ayni suficientes para hacer esta pregunta',
          HttpStatus.BAD_REQUEST,
        );
      }
      if (error.message.includes('PROFILE_NOT_FOUND')) {
        throw new DomainException(
          'PROFILE_NOT_FOUND',
          'Tu perfil aún no existe, vuelve a iniciar sesión',
          HttpStatus.NOT_FOUND,
        );
      }
      assertNoDatabaseError(error);
    }
    const rows = (data ?? []) as CommunityQuestionRecord[];
    return rows[0];
  }

  async answerQuestion(
    questionId: string,
    responderId: string,
    content: string,
    rewardAmount: number,
  ): Promise<CommunityAnswerRecord> {
    const { data, error } = await this.supabaseService.client.rpc(
      'answer_community_question',
      {
        p_question_id: questionId,
        p_responder_id: responderId,
        p_content: content,
        p_reward_amount: rewardAmount,
      },
    );
    if (error) {
      if (error.message.includes('QUESTION_NOT_FOUND')) {
        throw new DomainException(
          'QUESTION_NOT_FOUND',
          'La pregunta no existe',
          HttpStatus.NOT_FOUND,
        );
      }
      if (error.message.includes('CANNOT_ANSWER_OWN_QUESTION')) {
        throw new DomainException(
          'CANNOT_ANSWER_OWN_QUESTION',
          'No puedes responder tu propia pregunta',
          HttpStatus.CONFLICT,
        );
      }
      if (error.message.includes('QUESTION_ALREADY_ANSWERED')) {
        throw new DomainException(
          'QUESTION_ALREADY_ANSWERED',
          'Otra persona ya respondió esta pregunta',
          HttpStatus.CONFLICT,
        );
      }
      if (error.message.includes('QUESTION_EXPIRED')) {
        throw new DomainException(
          'QUESTION_EXPIRED',
          'La pregunta ya expiró y los puntos fueron devueltos',
          HttpStatus.CONFLICT,
        );
      }
      assertNoDatabaseError(error);
    }
    const rows = (data ?? []) as CommunityAnswerRecord[];
    return rows[0];
  }

  async expireOpenQuestions(): Promise<number> {
    const { data, error } = await this.supabaseService.client.rpc(
      'expire_community_questions',
    );
    assertNoDatabaseError(error);
    return (data as number) ?? 0;
  }

  async findById(questionId: string): Promise<CommunityQuestionRecord | null> {
    const { data, error } = await this.supabaseService.client
      .from('community_questions')
      .select(QUESTION_WITH_LINE_COLUMNS)
      .eq('id', questionId)
      .maybeSingle();
    assertNoDatabaseError(error);
    return data as CommunityQuestionRecord | null;
  }

  async findRecentByAsker(
    askerId: string,
    limit: number,
  ): Promise<CommunityQuestionRecord[]> {
    const { data, error } = await this.supabaseService.client
      .from('community_questions')
      .select(QUESTION_WITH_LINE_COLUMNS)
      .eq('asker_id', askerId)
      .order('created_at', { ascending: false })
      .limit(limit);
    assertNoDatabaseError(error);
    return (data ?? []) as CommunityQuestionRecord[];
  }

  async findOpenByLines(
    lineIds: string[],
    excludedAskerId: string,
  ): Promise<CommunityQuestionRecord[]> {
    const { data, error } = await this.supabaseService.client
      .from('community_questions')
      .select(QUESTION_WITH_LINE_COLUMNS)
      .in('line_id', lineIds)
      .eq('status', CommunityQuestionStatus.Open)
      .gt('expires_at', new Date().toISOString())
      .neq('asker_id', excludedAskerId)
      .order('created_at', { ascending: false });
    assertNoDatabaseError(error);
    return (data ?? []) as CommunityQuestionRecord[];
  }

  async findAnswersByQuestionIds(
    questionIds: string[],
  ): Promise<CommunityAnswerRecord[]> {
    if (questionIds.length === 0) {
      return [];
    }
    const { data, error } = await this.supabaseService.client
      .from('community_answers')
      .select('*')
      .in('question_id', questionIds)
      .order('created_at', { ascending: true });
    assertNoDatabaseError(error);
    return (data ?? []) as CommunityAnswerRecord[];
  }
}
