import { Injectable } from '@nestjs/common';
import { CreateFavoriteDto } from '../dto/create-favorite.dto';
import {
  FavoriteRecord,
  FavoritesRepository,
} from '../repositories/favorites.repository';

export interface Favorite {
  id: string;
  name: string;
  lat: number;
  lng: number;
  createdAt: string;
}

@Injectable()
export class FavoritesService {
  constructor(private readonly favoritesRepository: FavoritesRepository) {}

  async list(userId: string): Promise<Favorite[]> {
    const records = await this.favoritesRepository.findByUser(userId);
    return records.map((record) => this.toFavorite(record));
  }

  async create(userId: string, dto: CreateFavoriteDto): Promise<Favorite> {
    const record = await this.favoritesRepository.create(
      userId,
      dto.name,
      dto.lat,
      dto.lng,
    );
    return this.toFavorite(record);
  }

  async delete(userId: string, favoriteId: string): Promise<void> {
    await this.favoritesRepository.delete(userId, favoriteId);
  }

  private toFavorite(record: FavoriteRecord): Favorite {
    return {
      id: record.id,
      name: record.name,
      lat: Number(record.lat),
      lng: Number(record.lng),
      createdAt: record.created_at,
    };
  }
}
