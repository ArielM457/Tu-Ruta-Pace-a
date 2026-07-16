import { Injectable } from '@nestjs/common';
import { assertNoDatabaseError } from '../../../integrations/supabase/database-error';
import { SupabaseService } from '../../../integrations/supabase/supabase.service';

export interface LocationShareRecord {
  id: string;
  user_id: string;
  trip_id: string;
  line_id: string;
  started_at: string;
  ended_at: string | null;
  points_awarded: number | null;
}

@Injectable()
export class LocationSharesRepository {
  constructor(private readonly supabaseService: SupabaseService) {}

  async create(
    userId: string,
    tripId: string,
    lineId: string,
  ): Promise<LocationShareRecord> {
    const { data, error } = await this.supabaseService.client
      .from('location_shares')
      .insert({
        user_id: userId,
        trip_id: tripId,
        line_id: lineId,
        started_at: new Date().toISOString(),
      })
      .select()
      .single();
    assertNoDatabaseError(error);
    return data as LocationShareRecord;
  }

  async findById(shareId: string): Promise<LocationShareRecord | null> {
    const { data, error } = await this.supabaseService.client
      .from('location_shares')
      .select('*')
      .eq('id', shareId)
      .maybeSingle();
    assertNoDatabaseError(error);
    return data as LocationShareRecord | null;
  }

  async findActiveByLine(lineId: string): Promise<LocationShareRecord[]> {
    const { data, error } = await this.supabaseService.client
      .from('location_shares')
      .select('*')
      .eq('line_id', lineId)
      .is('ended_at', null);
    assertNoDatabaseError(error);
    return (data ?? []) as LocationShareRecord[];
  }

  async endActiveSharesForUser(userId: string): Promise<void> {
    const { error } = await this.supabaseService.client
      .from('location_shares')
      .update({ ended_at: new Date().toISOString(), points_awarded: 0 })
      .eq('user_id', userId)
      .is('ended_at', null);
    assertNoDatabaseError(error);
  }

  async closeShare(
    shareId: string,
    endedAt: string,
    pointsAwarded: number,
  ): Promise<LocationShareRecord> {
    const { data, error } = await this.supabaseService.client
      .from('location_shares')
      .update({ ended_at: endedAt, points_awarded: pointsAwarded })
      .eq('id', shareId)
      .select()
      .single();
    assertNoDatabaseError(error);
    return data as LocationShareRecord;
  }
}
