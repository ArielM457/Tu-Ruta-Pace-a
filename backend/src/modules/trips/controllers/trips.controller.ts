import {
  Body,
  Controller,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
} from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../../common/types/domain';
import { CreateTripDto } from '../dto/create-trip.dto';
import { Trip, TripsService } from '../services/trips.service';

@Controller('trips')
export class TripsController {
  constructor(private readonly tripsService: TripsService) {}

  @Post()
  start(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateTripDto,
  ): Promise<Trip> {
    return this.tripsService.startTrip(user.userId, dto);
  }

  @Patch(':id/finish')
  finish(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) tripId: string,
  ): Promise<Trip> {
    return this.tripsService.finishTrip(user.userId, tripId);
  }
}
