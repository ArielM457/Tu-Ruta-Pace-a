import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
} from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../../common/types/domain';
import { BootstrapProfileDto } from '../dto/bootstrap-profile.dto';
import { CreateFavoriteDto } from '../dto/create-favorite.dto';
import { UpdateProfileDto } from '../dto/update-profile.dto';
import { Favorite, FavoritesService } from '../services/favorites.service';
import { HelpStats, HelpStatsService } from '../services/help-stats.service';
import { ProfileResponse, UsersService } from '../services/users.service';

@Controller('users')
export class UsersController {
  constructor(
    private readonly usersService: UsersService,
    private readonly favoritesService: FavoritesService,
    private readonly helpStatsService: HelpStatsService,
  ) {}

  @Post('me/bootstrap')
  bootstrap(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: BootstrapProfileDto,
  ): Promise<ProfileResponse> {
    return this.usersService.bootstrapProfile(user.userId, dto);
  }

  @Get('me')
  getMe(@CurrentUser() user: AuthenticatedUser): Promise<ProfileResponse> {
    return this.usersService.getProfile(user.userId);
  }

  @Get('me/help-stats')
  getHelpStats(@CurrentUser() user: AuthenticatedUser): Promise<HelpStats> {
    return this.helpStatsService.get(user.userId);
  }

  @Patch('me')
  updateMe(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateProfileDto,
  ): Promise<ProfileResponse> {
    return this.usersService.updateProfile(user.userId, dto);
  }

  @Get('me/favorites')
  getFavorites(@CurrentUser() user: AuthenticatedUser): Promise<Favorite[]> {
    return this.favoritesService.list(user.userId);
  }

  @Post('me/favorites')
  createFavorite(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateFavoriteDto,
  ): Promise<Favorite> {
    return this.favoritesService.create(user.userId, dto);
  }

  @Delete('me/favorites/:id')
  deleteFavorite(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) favoriteId: string,
  ): Promise<void> {
    return this.favoritesService.delete(user.userId, favoriteId);
  }
}
