import { Module } from '@nestjs/common';
import { TransportsModule } from '../transports/transports.module';
import { TripsModule } from '../trips/trips.module';
import { UsersModule } from '../users/users.module';
import { AyniController } from './controllers/ayni.controller';
import { CollaborationController } from './controllers/collaboration.controller';
import { AyniTransactionsRepository } from './repositories/ayni-transactions.repository';
import { LocationPingsRepository } from './repositories/location-pings.repository';
import { LocationSharesRepository } from './repositories/location-shares.repository';
import { AyniPointsService } from './services/ayni-points.service';
import { LocationSharesService } from './services/location-shares.service';
import { VehicleLocationService } from './services/vehicle-location.service';

@Module({
  imports: [TripsModule, TransportsModule, UsersModule],
  controllers: [CollaborationController, AyniController],
  providers: [
    AyniPointsService,
    LocationSharesService,
    VehicleLocationService,
    AyniTransactionsRepository,
    LocationSharesRepository,
    LocationPingsRepository,
  ],
})
export class CollaborationModule {}
