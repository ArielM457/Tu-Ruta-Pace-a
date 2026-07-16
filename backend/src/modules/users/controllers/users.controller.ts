import { Body, Controller, Get, Patch, Post } from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../../common/types/domain';
import { BootstrapProfileDto } from '../dto/bootstrap-profile.dto';
import { UpdateProfileDto } from '../dto/update-profile.dto';
import { ProfileResponse, UsersService } from '../services/users.service';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

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

  @Patch('me')
  updateMe(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: UpdateProfileDto,
  ): Promise<ProfileResponse> {
    return this.usersService.updateProfile(user.userId, dto);
  }
}
