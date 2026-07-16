import { Body, Controller, Post } from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../../common/types/domain';
import { RouteRecommendationRequestDto } from '../dto/route-recommendation-request.dto';
import {
  RecommendationResponse,
  RecommendationService,
} from '../services/recommendation.service';

@Controller('routing')
export class RoutingController {
  constructor(private readonly recommendationService: RecommendationService) {}

  @Post('recommendations')
  recommend(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RouteRecommendationRequestDto,
  ): Promise<RecommendationResponse> {
    return this.recommendationService.recommend(user.userId, dto);
  }
}
