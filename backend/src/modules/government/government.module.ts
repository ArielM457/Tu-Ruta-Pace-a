import { Module } from '@nestjs/common';
import { IncidentsModule } from '../incidents/incidents.module';
import { GovernmentController } from './controllers/government.controller';
import { GovernmentService } from './services/government.service';

@Module({
  imports: [IncidentsModule],
  controllers: [GovernmentController],
  providers: [GovernmentService],
})
export class GovernmentModule {}
