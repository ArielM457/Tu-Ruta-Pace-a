import { Injectable } from '@nestjs/common';
import { assertNoDatabaseError } from '../../../integrations/supabase/database-error';
import { SupabaseService } from '../../../integrations/supabase/supabase.service';

export interface TransportLineRecord {
  id: string;
  kind: string;
  name: string;
  color: string | null;
  fare_bs: number;
  service_start: string | null;
  service_end: string | null;
  is_active: boolean;
}

export interface TransportStopRecord {
  id: string;
  line_id: string;
  name: string;
  lat: number;
  lng: number;
  sequence: number;
  is_accessible: boolean;
}

export interface LineWithStopsRecord extends TransportLineRecord {
  transport_stops: TransportStopRecord[];
}

@Injectable()
export class TransportLinesRepository {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findActiveLines(): Promise<TransportLineRecord[]> {
    const { data, error } = await this.supabaseService.client
      .from('transport_lines')
      .select('*')
      .eq('is_active', true)
      .order('name');
    assertNoDatabaseError(error);
    return (data ?? []) as TransportLineRecord[];
  }

  async findLineById(lineId: string): Promise<TransportLineRecord | null> {
    const { data, error } = await this.supabaseService.client
      .from('transport_lines')
      .select('*')
      .eq('id', lineId)
      .maybeSingle();
    assertNoDatabaseError(error);
    return data as TransportLineRecord | null;
  }

  async findStopsByLine(lineId: string): Promise<TransportStopRecord[]> {
    const { data, error } = await this.supabaseService.client
      .from('transport_stops')
      .select('*')
      .eq('line_id', lineId)
      .order('sequence');
    assertNoDatabaseError(error);
    return (data ?? []) as TransportStopRecord[];
  }

  async findStopById(stopId: string): Promise<TransportStopRecord | null> {
    const { data, error } = await this.supabaseService.client
      .from('transport_stops')
      .select('*')
      .eq('id', stopId)
      .maybeSingle();
    assertNoDatabaseError(error);
    return data as TransportStopRecord | null;
  }

  async findActiveLinesWithStops(
    kinds: string[],
  ): Promise<LineWithStopsRecord[]> {
    const { data, error } = await this.supabaseService.client
      .from('transport_lines')
      .select('*, transport_stops(*)')
      .eq('is_active', true)
      .in('kind', kinds);
    assertNoDatabaseError(error);
    return (data ?? []) as LineWithStopsRecord[];
  }
}
