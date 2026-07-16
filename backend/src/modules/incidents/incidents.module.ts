import { Module } from '@nestjs/common';
import { IncidentsController } from './controllers/incidents.controller';
import { IncidentsRepository } from './repositories/incidents.repository';
import { IncidentExpirationService } from './services/incident-expiration.service';
import { IncidentsService } from './services/incidents.service';

@Module({
  controllers: [IncidentsController],
  providers: [IncidentsService, IncidentExpirationService, IncidentsRepository],
  exports: [IncidentsService],
})
export class IncidentsModule {}
