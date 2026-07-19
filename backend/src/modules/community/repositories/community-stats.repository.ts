import { Injectable } from '@nestjs/common';
import { assertNoDatabaseError } from '../../../integrations/supabase/database-error';
import { SupabaseService } from '../../../integrations/supabase/supabase.service';

export interface WeeklyRankingRow {
  user_id: string;
  display_name: string | null;
  points: number;
  rnk: number;
}

export interface CommunityFeedRow {
  id: string;
  user_id: string;
  display_name: string | null;
  reason: string;
  amount: number;
  created_at: string;
}

@Injectable()
export class CommunityStatsRepository {
  constructor(private readonly supabaseService: SupabaseService) {}

  async getWeeklyRanking(): Promise<WeeklyRankingRow[]> {
    const { data, error } = await this.supabaseService.client.rpc(
      'community_weekly_ranking',
    );
    assertNoDatabaseError(error);
    return (data ?? []) as WeeklyRankingRow[];
  }

  async getFeed(limit: number): Promise<CommunityFeedRow[]> {
    const { data, error } = await this.supabaseService.client.rpc(
      'community_feed',
      { p_limit: limit },
    );
    assertNoDatabaseError(error);
    return (data ?? []) as CommunityFeedRow[];
  }
}
