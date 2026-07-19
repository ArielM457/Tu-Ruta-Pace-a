import { HttpStatus, Injectable } from '@nestjs/common';
import { DomainException } from '../../../common/exceptions/domain.exception';
import { assertNoDatabaseError } from '../../../integrations/supabase/database-error';
import { SupabaseService } from '../../../integrations/supabase/supabase.service';

export interface FavoriteRecord {
  id: string;
  user_id: string;
  name: string;
  lat: number;
  lng: number;
  created_at: string;
}

@Injectable()
export class FavoritesRepository {
  constructor(private readonly supabaseService: SupabaseService) {}

  async findByUser(userId: string): Promise<FavoriteRecord[]> {
    const { data, error } = await this.supabaseService.client
      .from('favorites')
      .select('*')
      .eq('user_id', userId)
      .order('created_at', { ascending: false });
    assertNoDatabaseError(error);
    return (data ?? []) as FavoriteRecord[];
  }

  async create(
    userId: string,
    name: string,
    lat: number,
    lng: number,
  ): Promise<FavoriteRecord> {
    const { data, error } = await this.supabaseService.client
      .from('favorites')
      .insert({ user_id: userId, name, lat, lng })
      .select()
      .single();
    assertNoDatabaseError(error);
    return data as FavoriteRecord;
  }

  async delete(userId: string, favoriteId: string): Promise<void> {
    const { data, error } = await this.supabaseService.client
      .from('favorites')
      .delete()
      .eq('id', favoriteId)
      .eq('user_id', userId)
      .select('id');
    assertNoDatabaseError(error);
    if (!data || data.length === 0) {
      throw new DomainException(
        'FAVORITE_NOT_FOUND',
        'La ruta favorita no existe',
        HttpStatus.NOT_FOUND,
      );
    }
  }
}
