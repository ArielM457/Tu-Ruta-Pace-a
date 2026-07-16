import { Injectable } from '@nestjs/common';
import { assertNoDatabaseError } from '../../../integrations/supabase/database-error';
import { SupabaseService } from '../../../integrations/supabase/supabase.service';

export interface SharedExperienceRecord {
  id: string;
  user_id: string | null;
  zone: string;
  time_slot: string;
  content: string;
  created_at: string;
}

const RECENT_EXPERIENCES_LIMIT = 20;

@Injectable()
export class SharedExperiencesRepository {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findRecent(): Promise<SharedExperienceRecord[]> {
    const { data, error } = await this.supabaseService.client
      .from('shared_experiences')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(RECENT_EXPERIENCES_LIMIT);
    assertNoDatabaseError(error);
    return (data ?? []) as SharedExperienceRecord[];
  }
}
