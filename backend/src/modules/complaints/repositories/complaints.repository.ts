import { Injectable } from '@nestjs/common';
import { assertNoDatabaseError } from '../../../integrations/supabase/database-error';
import { SupabaseService } from '../../../integrations/supabase/supabase.service';

export interface ComplaintRecord {
  id: string;
  user_id: string;
  vehicle_identifier: string | null;
  transport_kind: string;
  line_id: string | null;
  stop_id: string | null;
  complaint: string;
  status: string;
  created_at: string;
}

export interface NewComplaintRecord {
  user_id: string;
  vehicle_identifier: string | null;
  transport_kind: string;
  line_id: string | null;
  stop_id: string | null;
  complaint: string;
}

@Injectable()
export class ComplaintsRepository {
  constructor(private readonly supabaseService: SupabaseService) {}

  async create(record: NewComplaintRecord): Promise<ComplaintRecord> {
    const { data, error } = await this.supabaseService.client
      .from('complaints')
      .insert(record)
      .select()
      .single();
    assertNoDatabaseError(error);
    return data as ComplaintRecord;
  }

  async findByUser(userId: string): Promise<ComplaintRecord[]> {
    const { data, error } = await this.supabaseService.client
      .from('complaints')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });
    assertNoDatabaseError(error);
    return (data ?? []) as ComplaintRecord[];
  }
}
