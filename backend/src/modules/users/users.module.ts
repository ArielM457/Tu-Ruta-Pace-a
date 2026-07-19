import { Module } from '@nestjs/common';
import { UsersController } from './controllers/users.controller';
import { FavoritesRepository } from './repositories/favorites.repository';
import { HelpStatsRepository } from './repositories/help-stats.repository';
import { ProfilesRepository } from './repositories/profiles.repository';
import { FavoritesService } from './services/favorites.service';
import { HelpStatsService } from './services/help-stats.service';
import { UsersService } from './services/users.service';

@Module({
  controllers: [UsersController],
  providers: [
    UsersService,
    ProfilesRepository,
    FavoritesService,
    FavoritesRepository,
    HelpStatsService,
    HelpStatsRepository,
  ],
  exports: [UsersService],
})
export class UsersModule {}
