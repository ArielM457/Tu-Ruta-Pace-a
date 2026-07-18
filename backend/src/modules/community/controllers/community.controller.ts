import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
} from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../../common/types/domain';
import { AnswerQuestionDto } from '../dto/answer-question.dto';
import { CreateQuestionDto } from '../dto/create-question.dto';
import {
  AnswerQuestionResult,
  CommunityQuestion,
  CommunityQuestionsService,
  LineActivity,
} from '../services/community-questions.service';

@Controller('community')
export class CommunityController {
  constructor(
    private readonly communityQuestionsService: CommunityQuestionsService,
  ) {}

  @Get('lines/:lineId/activity')
  getLineActivity(
    @CurrentUser() user: AuthenticatedUser,
    @Param('lineId', ParseUUIDPipe) lineId: string,
  ): Promise<LineActivity> {
    return this.communityQuestionsService.getLineActivity(user.userId, lineId);
  }

  @Post('questions')
  askQuestion(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateQuestionDto,
  ): Promise<CommunityQuestion> {
    return this.communityQuestionsService.askQuestion(user.userId, dto);
  }

  @Get('questions/mine')
  getMyQuestions(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<CommunityQuestion[]> {
    return this.communityQuestionsService.getMyQuestions(user.userId);
  }

  @Get('questions/pending')
  getPendingQuestions(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<CommunityQuestion[]> {
    return this.communityQuestionsService.getPendingQuestionsForHelper(
      user.userId,
    );
  }

  @Post('questions/:id/answers')
  answerQuestion(
    @CurrentUser() user: AuthenticatedUser,
    @Param('id', ParseUUIDPipe) questionId: string,
    @Body() dto: AnswerQuestionDto,
  ): Promise<AnswerQuestionResult> {
    return this.communityQuestionsService.answerQuestion(
      user.userId,
      questionId,
      dto,
    );
  }
}
