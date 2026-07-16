import { Module } from '@nestjs/common';
import { SafetyController } from './controllers/safety.controller';
import { RiskZonesRepository } from './repositories/risk-zones.repository';
import { SafetyService } from './services/safety.service';

@Module({
  controllers: [SafetyController],
  providers: [SafetyService, RiskZonesRepository],
  exports: [SafetyService],
})
export class SafetyModule {}
