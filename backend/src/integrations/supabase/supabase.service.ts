import { Injectable } from '@nestjs/common';
import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { AppConfigService } from '../../config/app-config.service';

@Injectable()
export class SupabaseService {
  private supabaseClient: SupabaseClient | null = null;

  constructor(private readonly appConfig: AppConfigService) {}

  get client(): SupabaseClient {
    if (!this.supabaseClient) {
      this.supabaseClient = createClient(
        this.appConfig.supabaseUrl,
        this.appConfig.supabaseServiceRoleKey,
        { auth: { persistSession: false, autoRefreshToken: false } },
      );
    }
    return this.supabaseClient;
  }
}
