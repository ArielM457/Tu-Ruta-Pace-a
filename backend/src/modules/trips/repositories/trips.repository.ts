import { Injectable } from '@nestjs/common';
import { TripStatus } from '../../../common/types/domain';
import { assertNoDatabaseError } from '../../../integrations/supabase/database-error';
import { SupabaseService } from '../../../integrations/supabase/supabase.service';

export interface TripRecord {
  id: string;
  user_id: string;
  route_snapshot: Record<string, unknown>;
  status: string;
  started_at: string;
  finished_at: string | null;
}

@Injectable()
export class TripsRepository {
  constructor(private readonly supabaseService: SupabaseService) {}

  async create(
    userId: string,
    routeSnapshot: Record<string, unknown>,
  ): Promise<TripRecord> {
    const { data, error } = await this.supabaseService.client
      .from('trips')
      .insert({
        user_id: userId,
        route_snapshot: routeSnapshot,
        status: TripStatus.Active,
        started_at: new Date().toISOString(),
      })
      .select()
      .single();
    assertNoDatabaseError(error);
    return data as TripRecord;
  }

  async findById(tripId: string): Promise<TripRecord | null> {
    const { data, error } = await this.supabaseService.client
      .from('trips')
      .select('*')
      .eq('id', tripId)
      .maybeSingle();
    assertNoDatabaseError(error);
    return data as TripRecord | null;
  }

  async findActiveByUser(userId: string): Promise<TripRecord | null> {
    const { data, error } = await this.supabaseService.client
      .from('trips')
      .select('*')
      .eq('user_id', userId)
      .eq('status', TripStatus.Active)
      .order('started_at', { ascending: false })
      .limit(1)
      .maybeSingle();
    assertNoDatabaseError(error);
    return data as TripRecord | null;
  }

  async listByUser(
    userId: string,
    page: number,
    pageSize: number,
  ): Promise<TripRecord[]> {
    const from = (page - 1) * pageSize;
    const to = from + pageSize - 1;
    const { data, error } = await this.supabaseService.client
      .from('trips')
      .select('*')
      .eq('user_id', userId)
      .order('started_at', { ascending: false })
      .range(from, to);
    assertNoDatabaseError(error);
    return (data ?? []) as TripRecord[];
  }

  async markFinished(tripId: string): Promise<TripRecord> {
    const { data, error } = await this.supabaseService.client
      .from('trips')
      .update({
        status: TripStatus.Finished,
        finished_at: new Date().toISOString(),
      })
      .eq('id', tripId)
      .select()
      .single();
    assertNoDatabaseError(error);
    return data as TripRecord;
  }

  async cancelActiveTrips(userId: string): Promise<void> {
    const { error } = await this.supabaseService.client
      .from('trips')
      .update({
        status: TripStatus.Cancelled,
        finished_at: new Date().toISOString(),
      })
      .eq('user_id', userId)
      .eq('status', TripStatus.Active);
    assertNoDatabaseError(error);
  }
}
