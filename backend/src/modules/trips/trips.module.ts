import { Module } from '@nestjs/common';
import { TripHistoryController } from './controllers/trip-history.controller';
import { TripsController } from './controllers/trips.controller';
import { TripsRepository } from './repositories/trips.repository';
import { TripsService } from './services/trips.service';

@Module({
  controllers: [TripsController, TripHistoryController],
  providers: [TripsService, TripsRepository],
  exports: [TripsService],
})
export class TripsModule {}
