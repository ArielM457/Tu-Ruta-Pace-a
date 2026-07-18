import { Module } from '@nestjs/common';
import { CollaborationModule } from '../collaboration/collaboration.module';
import { TransportsModule } from '../transports/transports.module';
import { UsersModule } from '../users/users.module';
import { CommunityController } from './controllers/community.controller';
import { CommunityQuestionsRepository } from './repositories/community-questions.repository';
import { CommunityQuestionsService } from './services/community-questions.service';
import { QuestionExpirationService } from './services/question-expiration.service';

@Module({
  imports: [CollaborationModule, TransportsModule, UsersModule],
  controllers: [CommunityController],
  providers: [
    CommunityQuestionsService,
    QuestionExpirationService,
    CommunityQuestionsRepository,
  ],
})
export class CommunityModule {}
