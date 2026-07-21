import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { CommunityQuestionsRepository } from '../repositories/community-questions.repository';

@Injectable()
export class QuestionExpirationService {
  private readonly logger = new Logger(QuestionExpirationService.name);

  constructor(
    private readonly communityQuestionsRepository: CommunityQuestionsRepository,
  ) {}

  @Cron(CronExpression.EVERY_MINUTE)
  async refundExpiredQuestions(): Promise<void> {
    try {
      const expiredCount =
        await this.communityQuestionsRepository.expireOpenQuestions();
      if (expiredCount > 0) {
        this.logger.log(
          `Se reembolsaron ${expiredCount} preguntas sin respuesta`,
        );
      }
    } catch (error) {
      this.logger.warn(
        `No se pudo expirar preguntas: ${(error as Error).message}`,
      );
    }
  }
}
