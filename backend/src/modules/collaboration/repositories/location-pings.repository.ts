import { Injectable } from '@nestjs/common';
import { assertNoDatabaseError } from '../../../integrations/supabase/database-error';
import { SupabaseService } from '../../../integrations/supabase/supabase.service';

export interface LocationPingRecord {
  id: number;
  share_id: string;
  lat: number;
  lng: number;
  recorded_at: string;
}

@Injectable()
export class LocationPingsRepository {
  constructor(private readonly supabaseService: SupabaseService) {}

  async record(
    shareId: string,
    lat: number,
    lng: number,
    recordedAt: string,
  ): Promise<void> {
    const { error } = await this.supabaseService.client
      .from('location_pings')
      .insert({ share_id: shareId, lat, lng, recorded_at: recordedAt });
    assertNoDatabaseError(error);
  }

  async findRecentByShares(
    shareIds: string[],
    since: string,
  ): Promise<LocationPingRecord[]> {
    if (shareIds.length === 0) {
      return [];
    }
    const { data, error } = await this.supabaseService.client
      .from('location_pings')
      .select('*')
      .in('share_id', shareIds)
      .gte('recorded_at', since)
      .order('recorded_at', { ascending: false });
    assertNoDatabaseError(error);
    return (data ?? []) as LocationPingRecord[];
  }
}
