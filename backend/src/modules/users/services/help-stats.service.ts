import { Injectable } from '@nestjs/common';
import { HelpStatsRepository } from '../repositories/help-stats.repository';

export interface HelpStats {
  peopleHelped: number;
}

@Injectable()
export class HelpStatsService {
  constructor(private readonly helpStatsRepository: HelpStatsRepository) {}

  async get(userId: string): Promise<HelpStats> {
    const peopleHelped =
      await this.helpStatsRepository.countHelpfulActions(userId);
    return { peopleHelped };
  }
}
