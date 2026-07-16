import { HttpStatus, Injectable } from '@nestjs/common';
import { DomainException } from '../../../common/exceptions/domain.exception';
import { assertNoDatabaseError } from '../../../integrations/supabase/database-error';
import { SupabaseService } from '../../../integrations/supabase/supabase.service';

export interface AyniTransactionRecord {
  id: string;
  user_id: string;
  amount: number;
  reason: string;
  reference_id: string | null;
  created_at: string;
}

@Injectable()
export class AyniTransactionsRepository {
  constructor(private readonly supabaseService: SupabaseService) {}

  async adjustPoints(
    userId: string,
    amount: number,
    reason: string,
    referenceId: string | null,
  ): Promise<number> {
    const { data, error } = await this.supabaseService.client.rpc(
      'adjust_ayni_points',
      {
        p_user_id: userId,
        p_amount: amount,
        p_reason: reason,
        p_reference_id: referenceId,
      },
    );
    if (error) {
      if (error.message.includes('INSUFFICIENT_AYNI_POINTS')) {
        throw new DomainException(
          'INSUFFICIENT_AYNI_POINTS',
          'No tienes puntos Ayni suficientes para esta consulta',
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
    return data as number;
  }

  async listByUser(
    userId: string,
    page: number,
    pageSize: number,
  ): Promise<AyniTransactionRecord[]> {
    const from = (page - 1) * pageSize;
    const to = from + pageSize - 1;
    const { data, error } = await this.supabaseService.client
      .from('ayni_transactions')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .range(from, to);
    assertNoDatabaseError(error);
    return (data ?? []) as AyniTransactionRecord[];
  }
}
