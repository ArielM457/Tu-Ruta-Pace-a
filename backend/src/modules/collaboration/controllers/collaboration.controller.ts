import {
  Body,
  Controller,
  HttpCode,
  HttpStatus,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
} from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../../common/types/domain';
import { RecordPingDto } from '../dto/record-ping.dto';
import { StartShareDto } from '../dto/start-share.dto';
import { VehicleQueryDto } from '../dto/vehicle-query.dto';
import {
  LocationShare,
  LocationSharesService,
} from '../services/location-shares.service';
import {
  VehicleLocationService,
  VehicleQueryResult,
} from '../services/vehicle-location.service';

@Controller('collaboration')
export class CollaborationController {
  constructor(
    private readonly locationSharesService: LocationSharesService,
    private readonly vehicleLocationService: VehicleLocationService,
  ) {}

  @Post('shares')
  startShare(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: StartShareDto,
  ): Promise<LocationShare> {
    return this.locationSharesService.startShare(user.userId, dto);
  }

  @Post('shares/:id/pings')
  @HttpCode(HttpStatus.NO_CONTENT)
  recordPing(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) shareId: string,
    @Body() dto: RecordPingDto,
  ): Promise<void> {
    return this.locationSharesService.recordPing(user.userId, shareId, dto);
  }

  @Patch('shares/:id/stop')
  stopShare(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) shareId: string,
  ): Promise<LocationShare & { newBalance: number }> {
    return this.locationSharesService.stopShare(user.userId, shareId);
  }

  @Post('vehicle-queries')
  queryVehicle(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: VehicleQueryDto,
  ): Promise<VehicleQueryResult> {
    return this.vehicleLocationService.queryVehicle(user.userId, dto);
  }
}
