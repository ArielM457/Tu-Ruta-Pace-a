import { Injectable } from '@nestjs/common';
import { Coordinate } from '../../../common/types/domain';
import { assertNoDatabaseError } from '../../../integrations/supabase/database-error';
import { SupabaseService } from '../../../integrations/supabase/supabase.service';

@Injectable()
export class RouteRequestsRepository {
  constructor(private readonly supabaseService: SupabaseService) {}

  async save(
    userId: string,
    origin: Coordinate,
    destination: Coordinate,
    priority: string,
  ): Promise<void> {
    const { error } = await this.supabaseService.client
      .from('route_requests')
      .insert({
        user_id: userId,
        origin_lat: origin.lat,
        origin_lng: origin.lng,
        destination_lat: destination.lat,
        destination_lng: destination.lng,
        priority,
      });
    assertNoDatabaseError(error);
  }
}
