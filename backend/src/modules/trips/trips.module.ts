import { Module } from '@nestjs/common';
import { TripsController } from './controllers/trips.controller';
import { TripsRepository } from './repositories/trips.repository';
import { TripsService } from './services/trips.service';

@Module({
  controllers: [TripsController],
  providers: [TripsService, TripsRepository],
  exports: [TripsService],
})
export class TripsModule {}
