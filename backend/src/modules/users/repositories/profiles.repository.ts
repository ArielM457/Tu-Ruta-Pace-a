import { Injectable } from '@nestjs/common';
import { assertNoDatabaseError } from '../../../integrations/supabase/database-error';
import { SupabaseService } from '../../../integrations/supabase/supabase.service';

export interface ProfileRecord {
  id: string;
  display_name: string | null;
  role: string;
  accessibility_profile: string;
  default_priority: string;
  ayni_points: number;
  created_at: string;
}

export interface ProfileChanges {
  display_name?: string;
  accessibility_profile?: string;
  default_priority?: string;
}

@Injectable()
export class ProfilesRepository {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findById(profileId: string): Promise<ProfileRecord | null> {
    const { data, error } = await this.supabaseService.client
      .from('profiles')
      .select('*')
      .eq('id', profileId)
      .maybeSingle();
    assertNoDatabaseError(error);
    return data as ProfileRecord | null;
  }

  async createIfMissing(
    profileId: string,
    displayName: string | null,
  ): Promise<ProfileRecord> {
    const existing = await this.findById(profileId);
    if (existing) {
      return existing;
    }
    const { data, error } = await this.supabaseService.client
      .from('profiles')
      .insert({ id: profileId, display_name: displayName })
      .select()
      .single();
    assertNoDatabaseError(error);
    return data as ProfileRecord;
  }

  async update(
    profileId: string,
    changes: ProfileChanges,
  ): Promise<ProfileRecord> {
    const { data, error } = await this.supabaseService.client
      .from('profiles')
      .update(changes)
      .eq('id', profileId)
      .select()
      .single();
    assertNoDatabaseError(error);
    return data as ProfileRecord;
  }
}
