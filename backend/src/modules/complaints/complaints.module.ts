import { Module } from '@nestjs/common';
import { TransportsModule } from '../transports/transports.module';
import { ComplaintsController } from './controllers/complaints.controller';
import { ComplaintsRepository } from './repositories/complaints.repository';
import { ComplaintsService } from './services/complaints.service';

@Module({
  imports: [TransportsModule],
  controllers: [ComplaintsController],
  providers: [ComplaintsService, ComplaintsRepository],
})
export class ComplaintsModule {}
