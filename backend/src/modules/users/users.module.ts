import { Module } from '@nestjs/common';
import { UsersController } from './controllers/users.controller';
import { ProfilesRepository } from './repositories/profiles.repository';
import { UsersService } from './services/users.service';

@Module({
  controllers: [UsersController],
  providers: [UsersService, ProfilesRepository],
  exports: [UsersService],
})
export class UsersModule {}
