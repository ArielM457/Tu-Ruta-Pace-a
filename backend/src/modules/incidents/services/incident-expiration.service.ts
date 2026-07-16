import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { IncidentsRepository } from '../repositories/incidents.repository';

@Injectable()
export class IncidentExpirationService {
  private readonly logger = new Logger(IncidentExpirationService.name);

  constructor(private readonly incidentsRepository: IncidentsRepository) {}

  @Cron(CronExpression.EVERY_HOUR)
  async resolveExpiredIncidents(): Promise<void> {
    try {
      await this.incidentsRepository.resolveExpired(new Date().toISOString());
    } catch (error) {
      this.logger.warn(
        `No se pudo expirar incidentes: ${(error as Error).message}`,
      );
    }
  }
}
