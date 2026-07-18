import { HttpStatus, Injectable } from '@nestjs/common';
import { DomainException } from '../../../common/exceptions/domain.exception';
import {
  CommunityQuestionKind,
  CommunityQuestionStatus,
} from '../../../common/types/domain';
import { AppConfigService } from '../../../config/app-config.service';
import { LocationSharesRepository } from '../../collaboration/repositories/location-shares.repository';
import { TransportsService } from '../../transports/services/transports.service';
import { UsersService } from '../../users/services/users.service';
import { AnswerQuestionDto } from '../dto/answer-question.dto';
import { CreateQuestionDto } from '../dto/create-question.dto';
import {
  CommunityAnswerRecord,
  CommunityQuestionRecord,
  CommunityQuestionsRepository,
} from '../repositories/community-questions.repository';

export interface CommunityAnswer {
  id: string;
  content: string;
  createdAt: string;
}

export interface CommunityQuestion {
  id: string;
  lineId: string;
  lineName: string | null;
  kind: CommunityQuestionKind;
  content: string | null;
  pointsCost: number;
  status: CommunityQuestionStatus;
  createdAt: string;
  expiresAt: string;
  answeredAt: string | null;
  answers: CommunityAnswer[];
}

export interface LineActivity {
  lineId: string;
  activePeople: number;
}

export interface AnswerQuestionResult {
  answer: CommunityAnswer;
  pointsAwarded: number;
  newBalance: number;
}

const MY_QUESTIONS_LIMIT = 10;

@Injectable()
export class CommunityQuestionsService {
  constructor(
    private readonly communityQuestionsRepository: CommunityQuestionsRepository,
    private readonly locationSharesRepository: LocationSharesRepository,
    private readonly transportsService: TransportsService,
    private readonly usersService: UsersService,
    private readonly appConfig: AppConfigService,
  ) {}

  async getLineActivity(userId: string, lineId: string): Promise<LineActivity> {
    await this.transportsService.getLine(lineId);
    const activePeople = await this.countActivePeopleOnLine(lineId, userId);
    return { lineId, activePeople };
  }

  async askQuestion(
    userId: string,
    dto: CreateQuestionDto,
  ): Promise<CommunityQuestion> {
    const line = await this.transportsService.getLine(dto.lineId);
    const activePeople = await this.countActivePeopleOnLine(dto.lineId, userId);
    if (activePeople === 0) {
      throw new DomainException(
        'NO_ACTIVE_COLLABORATORS',
        'Aún no hay personas activas en esta ruta; no se te cobraron puntos',
        HttpStatus.CONFLICT,
      );
    }
    const record = await this.communityQuestionsRepository.createQuestion(
      userId,
      dto.lineId,
      dto.kind,
      dto.content ?? null,
      this.appConfig.ayniQuestionCost,
      this.appConfig.ayniQuestionTimeoutMinutes,
    );
    return this.toQuestion(record, [], line.name);
  }

  async getMyQuestions(userId: string): Promise<CommunityQuestion[]> {
    const records = await this.communityQuestionsRepository.findRecentByAsker(
      userId,
      MY_QUESTIONS_LIMIT,
    );
    const answers =
      await this.communityQuestionsRepository.findAnswersByQuestionIds(
        records.map((record) => record.id),
      );
    return records.map((record) =>
      this.toQuestion(
        record,
        answers.filter((answer) => answer.question_id === record.id),
      ),
    );
  }

  async getPendingQuestionsForHelper(
    userId: string,
  ): Promise<CommunityQuestion[]> {
    const activeShares =
      await this.locationSharesRepository.findActiveByUser(userId);
    if (activeShares.length === 0) {
      return [];
    }
    const lineIds = [...new Set(activeShares.map((share) => share.line_id))];
    const records = await this.communityQuestionsRepository.findOpenByLines(
      lineIds,
      userId,
    );
    return records.map((record) => this.toQuestion(record, []));
  }

  async answerQuestion(
    userId: string,
    questionId: string,
    dto: AnswerQuestionDto,
  ): Promise<AnswerQuestionResult> {
    const question =
      await this.communityQuestionsRepository.findById(questionId);
    if (!question) {
      throw new DomainException(
        'QUESTION_NOT_FOUND',
        'La pregunta no existe',
        HttpStatus.NOT_FOUND,
      );
    }
    await this.assertUserIsActiveOnLine(userId, question.line_id);
    const answerRecord = await this.communityQuestionsRepository.answerQuestion(
      questionId,
      userId,
      dto.content,
    );
    const profile = await this.usersService.getProfile(userId);
    return {
      answer: this.toAnswer(answerRecord),
      pointsAwarded: answerRecord.points_awarded,
      newBalance: profile.ayniPoints,
    };
  }

  private async assertUserIsActiveOnLine(
    userId: string,
    lineId: string,
  ): Promise<void> {
    const activeShares =
      await this.locationSharesRepository.findActiveByLine(lineId);
    const isActive = activeShares.some((share) => share.user_id === userId);
    if (!isActive) {
      throw new DomainException(
        'NO_ACTIVE_SHARE_ON_LINE',
        'Solo puedes responder preguntas de una ruta en la que estás compartiendo ubicación',
        HttpStatus.CONFLICT,
      );
    }
  }

  private async countActivePeopleOnLine(
    lineId: string,
    excludedUserId: string,
  ): Promise<number> {
    const activeShares =
      await this.locationSharesRepository.findActiveByLine(lineId);
    const distinctUserIds = new Set(
      activeShares
        .map((share) => share.user_id)
        .filter((shareUserId) => shareUserId !== excludedUserId),
    );
    return distinctUserIds.size;
  }

  private toQuestion(
    record: CommunityQuestionRecord,
    answerRecords: CommunityAnswerRecord[],
    lineName?: string,
  ): CommunityQuestion {
    return {
      id: record.id,
      lineId: record.line_id,
      lineName: lineName ?? record.transport_lines?.name ?? null,
      kind: record.kind as CommunityQuestionKind,
      content: record.content,
      pointsCost: record.points_cost,
      status: record.status as CommunityQuestionStatus,
      createdAt: record.created_at,
      expiresAt: record.expires_at,
      answeredAt: record.answered_at,
      answers: answerRecords.map((answer) => this.toAnswer(answer)),
    };
  }

  private toAnswer(record: CommunityAnswerRecord): CommunityAnswer {
    return {
      id: record.id,
      content: record.content,
      createdAt: record.created_at,
    };
  }
}
