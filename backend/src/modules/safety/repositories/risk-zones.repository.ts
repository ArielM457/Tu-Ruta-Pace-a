import { Injectable } from '@nestjs/common';
import { assertNoDatabaseError } from '../../../integrations/supabase/database-error';
import { SupabaseService } from '../../../integrations/supabase/supabase.service';

export interface RiskZoneRecord {
  id: string;
  name: string;
  lat: number;
  lng: number;
  radius_meters: number;
  risk_start: string;
  risk_end: string;
  level: string;
  source: string;
}

@Injectable()
export class RiskZonesRepository {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findAll(): Promise<RiskZoneRecord[]> {
    const { data, error } = await this.supabaseService.client
      .from('risk_zones')
      .select('*');
    assertNoDatabaseError(error);
    return (data ?? []) as RiskZoneRecord[];
  }
}
