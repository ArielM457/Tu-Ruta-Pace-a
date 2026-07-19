import { Injectable } from '@nestjs/common';
import { AppConfigService } from '../../../config/app-config.service';
import {
  AyniTransactionRecord,
  AyniTransactionsRepository,
} from '../repositories/ayni-transactions.repository';

export enum AyniReason {
  SharedLocation = 'shared_location',
  QueriedVehicle = 'queried_vehicle',
  AskedQuestion = 'asked_question',
  AnsweredQuestion = 'answered_question',
  QuestionRefunded = 'question_refunded',
  VerifiedReport = 'verified_report',
  ConfirmedIncident = 'confirmed_incident',
  Bonus = 'bonus',
}

export interface AyniMovement {
  id: string;
  amount: number;
  reason: string;
  referenceId: string | null;
  createdAt: string;
}

@Injectable()
export class AyniPointsService {
  constructor(
    private readonly ayniTransactionsRepository: AyniTransactionsRepository,
    private readonly appConfig: AppConfigService,
  ) {}

  pointsForSharedMinutes(sharedMinutes: number): number {
    const earned = Math.floor(sharedMinutes * this.appConfig.ayniRatePerMinute);
    return Math.min(
      Math.max(earned, 0),
      this.appConfig.ayniMaximumPointsPerShare,
    );
  }

  get queryCost(): number {
    return this.appConfig.ayniQueryCost;
  }

  get questionCost(): number {
    return this.appConfig.ayniQuestionCost;
  }

  get answerReward(): number {
    return this.appConfig.ayniAnswerReward;
  }

  get verifiedReportReward(): number {
    return this.appConfig.ayniVerifiedReportReward;
  }

  get confirmedIncidentReward(): number {
    return this.appConfig.ayniConfirmedIncidentReward;
  }

  async award(
    userId: string,
    amount: number,
    reason: AyniReason,
    referenceId: string | null,
  ): Promise<number> {
    if (amount <= 0) {
      return this.currentBalanceAfterNoOp(userId);
    }
    return this.ayniTransactionsRepository.adjustPoints(
      userId,
      amount,
      reason,
      referenceId,
    );
  }

  async awardOncePerReference(
    userId: string,
    amount: number,
    reason: AyniReason,
    referenceId: string,
  ): Promise<void> {
    if (amount <= 0) {
      return;
    }
    await this.ayniTransactionsRepository.adjustPointsOncePerReference(
      userId,
      amount,
      reason,
      referenceId,
    );
  }

  async charge(
    userId: string,
    amount: number,
    reason: AyniReason,
    referenceId: string | null,
  ): Promise<number> {
    return this.ayniTransactionsRepository.adjustPoints(
      userId,
      -Math.abs(amount),
      reason,
      referenceId,
    );
  }

  async history(
    userId: string,
    page: number,
    pageSize: number,
  ): Promise<AyniMovement[]> {
    const records = await this.ayniTransactionsRepository.listByUser(
      userId,
      page,
      pageSize,
    );
    return records.map((record) => this.toMovement(record));
  }

  private async currentBalanceAfterNoOp(userId: string): Promise<number> {
    return this.ayniTransactionsRepository.adjustPoints(
      userId,
      0,
      AyniReason.Bonus,
      null,
    );
  }

  private toMovement(record: AyniTransactionRecord): AyniMovement {
    return {
      id: record.id,
      amount: record.amount,
      reason: record.reason,
      referenceId: record.reference_id,
      createdAt: record.created_at,
    };
  }
}
