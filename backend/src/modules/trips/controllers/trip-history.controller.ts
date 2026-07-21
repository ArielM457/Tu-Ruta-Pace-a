import { Controller, Get, Query } from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../../common/types/domain';
import { TripHistoryQueryDto } from '../dto/trip-history-query.dto';
import { Trip, TripsService } from '../services/trips.service';

export interface TripHistoryResponse {
  trips: Trip[];
  page: number;
  pageSize: number;
}

const DEFAULT_PAGE_SIZE = 20;

@Controller('users/me/trips')
export class TripHistoryController {
  constructor(private readonly tripsService: TripsService) {}

  @Get()
  async getHistory(
    @CurrentUser() user: AuthenticatedUser,
    @Query() query: TripHistoryQueryDto,
  ): Promise<TripHistoryResponse> {
    const page = query.page ?? 1;
    const pageSize = query.pageSize ?? DEFAULT_PAGE_SIZE;
    const trips = await this.tripsService.listTrips(
      user.userId,
      page,
      pageSize,
    );
    return { trips, page, pageSize };
  }
}
