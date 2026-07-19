import { Module } from '@nestjs/common';
import { TripsModule } from '../trips/trips.module';
import { UsersModule } from '../users/users.module';
import { FamilyController } from './controllers/family.controller';
import { FamilyRepository } from './repositories/family.repository';
import { FamilyService } from './services/family.service';

@Module({
  imports: [TripsModule, UsersModule],
  controllers: [FamilyController],
  providers: [FamilyService, FamilyRepository],
})
export class FamilyModule {}
