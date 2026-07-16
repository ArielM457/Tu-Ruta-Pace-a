import { Module } from '@nestjs/common';
import { GoogleMapsModule } from '../../integrations/google-maps/google-maps.module';
import { IncidentsModule } from '../incidents/incidents.module';
import { EmergencyController } from './controllers/emergency.controller';
import { HealthFacilitiesRepository } from './repositories/health-facilities.repository';
import { EmergencyService } from './services/emergency.service';

@Module({
  imports: [GoogleMapsModule, IncidentsModule],
  controllers: [EmergencyController],
  providers: [EmergencyService, HealthFacilitiesRepository],
})
export class EmergencyModule {}
