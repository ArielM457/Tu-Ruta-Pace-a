import { Injectable } from '@nestjs/common';
import { assertNoDatabaseError } from '../../../integrations/supabase/database-error';
import { SupabaseService } from '../../../integrations/supabase/supabase.service';

const HELPFUL_REASONS = ['answered_question', 'confirmed_incident'];

@Injectable()
export class HelpStatsRepository {
  constructor(private readonly supabaseService: SupabaseService) {}

  async countHelpfulActions(userId: string): Promise<number> {
    const { count, error } = await this.supabaseService.client
      .from('ayni_transactions')
      .select('id', { count: 'exact', head: true })
      .eq('user_id', userId)
      .in('reason', HELPFUL_REASONS);
    assertNoDatabaseError(error);
    return count ?? 0;
  }
}
