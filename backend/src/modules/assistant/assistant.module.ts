import { Module } from '@nestjs/common';
import { AzureFoundryModule } from '../../integrations/azure-foundry/azure-foundry.module';
import { IncidentsModule } from '../incidents/incidents.module';
import { TransportsModule } from '../transports/transports.module';
import { TripsModule } from '../trips/trips.module';
import { AssistantController } from './controllers/assistant.controller';
import { SharedExperiencesRepository } from './repositories/shared-experiences.repository';
import { AssistantContextService } from './services/assistant-context.service';
import { AssistantService } from './services/assistant.service';

@Module({
  imports: [AzureFoundryModule, TripsModule, IncidentsModule, TransportsModule],
  controllers: [AssistantController],
  providers: [
    AssistantService,
    AssistantContextService,
    SharedExperiencesRepository,
  ],
})
export class AssistantModule {}
