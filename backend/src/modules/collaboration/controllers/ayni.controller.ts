import { Controller, Get, Query } from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../../common/types/domain';
import { UsersService } from '../../users/services/users.service';
import { AyniHistoryQueryDto } from '../dto/ayni-history-query.dto';
import {
  AyniMovement,
  AyniPointsService,
} from '../services/ayni-points.service';

export interface AyniHistoryResponse {
  balance: number;
  movements: AyniMovement[];
  page: number;
  pageSize: number;
}

const DEFAULT_PAGE_SIZE = 20;

@Controller('users/me/ayni')
export class AyniController {
  constructor(
    private readonly ayniPointsService: AyniPointsService,
    private readonly usersService: UsersService,
  ) {}

  @Get()
  async getHistory(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: AyniHistoryQueryDto,
  ): Promise<AyniHistoryResponse> {
    const page = query.page ?? 1;
    const pageSize = query.pageSize ?? DEFAULT_PAGE_SIZE;
    const [profile, movements] = await Promise.all([
      this.usersService.getProfile(user.userId),
      this.ayniPointsService.history(user.userId, page, pageSize),
    ]);
    return { balance: profile.ayniPoints, movements, page, pageSize };
  }
}
