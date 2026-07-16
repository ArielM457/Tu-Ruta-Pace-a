import { Module } from '@nestjs/common';
import { TransportsController } from './controllers/transports.controller';
import { TransportLinesRepository } from './repositories/transport-lines.repository';
import { TransportsService } from './services/transports.service';

@Module({
  controllers: [TransportsController],
  providers: [TransportsService, TransportLinesRepository],
  exports: [TransportsService],
})
export class TransportsModule {}
