import { Controller, Get, Query } from '@nestjs/common';
import { RiskZonesQueryDto } from '../dto/risk-zones-query.dto';
import { RiskZone, SafetyService } from '../services/safety.service';

@Controller('safety')
export class SafetyController {
  constructor(private readonly safetyService: SafetyService) {}

  @Get('risk-zones')
  listActiveRiskZones(@Query() query: RiskZonesQueryDto): Promise<RiskZone[]> {
    const at = query.activeAt ? new Date(query.activeAt) : new Date();
    return this.safetyService.getZonesActiveAt(at);
  }
}
