import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { EmergencyRouteRequestDto } from '../dto/emergency-route.dto';
import { FacilitiesNearQueryDto } from '../dto/facilities-near-query.dto';
import {
  EmergencyContact,
  EmergencyRouteResponse,
  EmergencyService,
  HealthFacility,
} from '../services/emergency.service';

@Controller('emergency')
export class EmergencyController {
  constructor(private readonly emergencyService: EmergencyService) {}

  @Post('route')
  buildRoute(
    @Body() dto: EmergencyRouteRequestDto,
  ): Promise<EmergencyRouteResponse> {
    return this.emergencyService.buildEmergencyRoute({
      lat: dto.origin.lat,
      lng: dto.origin.lng,
    });
  }

  @Get('contacts')
  getContacts(): EmergencyContact[] {
    return this.emergencyService.getContacts();
  }

  @Get('facilities/near')
  findFacilitiesNear(
    @Query() query: FacilitiesNearQueryDto,
  ): Promise<HealthFacility[]> {
    return this.emergencyService.findFacilitiesNear(
      { lat: query.lat, lng: query.lng },
      query.radius,
      query.kind,
    );
  }
}
