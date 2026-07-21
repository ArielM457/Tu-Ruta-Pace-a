import { Body, Controller, Get, Post, Query } from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../../common/types/domain';
import {
  GooglePlacesService,
  PlaceSuggestion,
} from '../../../integrations/google-maps/google-places.service';
import { PlacesAutocompleteQueryDto } from '../dto/places-autocomplete-query.dto';
import { RouteRecommendationRequestDto } from '../dto/route-recommendation-request.dto';
import {
  RecommendationResponse,
  RecommendationService,
} from '../services/recommendation.service';

@Controller('routing')
export class RoutingController {
  constructor(
    private readonly recommendationService: RecommendationService,
    private readonly googlePlacesService: GooglePlacesService,
  ) {}

  @Post('recommendations')
  recommend(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: RouteRecommendationRequestDto,
  ): Promise<RecommendationResponse> {
    return this.recommendationService.recommend(user.userId, dto);
  }

  @Get('places/autocomplete')
  autocompletePlaces(
    @Query() query: PlacesAutocompleteQueryDto,
  ): Promise<PlaceSuggestion[]> {
    return this.googlePlacesService.autocomplete(query.q);
  }
}
