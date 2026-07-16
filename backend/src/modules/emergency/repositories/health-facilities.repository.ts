import { Injectable } from '@nestjs/common';
import { assertNoDatabaseError } from '../../../integrations/supabase/database-error';
import { SupabaseService } from '../../../integrations/supabase/supabase.service';

export interface HealthFacilityRecord {
  id: string;
  name: string;
  kind: string;
  lat: number;
  lng: number;
  phone: string | null;
}

@Injectable()
export class HealthFacilitiesRepository {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findAll(): Promise<HealthFacilityRecord[]> {
    const { data, error } = await this.supabaseService.client
      .from('health_facilities')
      .select('*');
    assertNoDatabaseError(error);
    return (data ?? []) as HealthFacilityRecord[];
  }

  async findByKind(kind: string): Promise<HealthFacilityRecord[]> {
    const { data, error } = await this.supabaseService.client
      .from('health_facilities')
      .select('*')
      .eq('kind', kind);
    assertNoDatabaseError(error);
    return (data ?? []) as HealthFacilityRecord[];
  }
}
