import { Module } from '@nestjs/common';
import { CollaborationModule } from '../collaboration/collaboration.module';
import { IncidentsController } from './controllers/incidents.controller';
import { IncidentsRepository } from './repositories/incidents.repository';
import { IncidentExpirationService } from './services/incident-expiration.service';
import { IncidentsService } from './services/incidents.service';

@Module({
  imports: [CollaborationModule],
  controllers: [IncidentsController],
  providers: [IncidentsService, IncidentExpirationService, IncidentsRepository],
  exports: [IncidentsService],
})
export class IncidentsModule {}
