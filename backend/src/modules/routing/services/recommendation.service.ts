import { Injectable, Logger } from '@nestjs/common';
import {
  AccessibilityProfile,
  Coordinate,
  TravelPriority,
} from '../../../common/types/domain';
import { GoogleDirectionsService } from '../../../integrations/google-maps/google-directions.service';
import { IncidentsService } from '../../incidents/services/incidents.service';
import { SafetyService } from '../../safety/services/safety.service';
import { TransportsService } from '../../transports/services/transports.service';
import { UsersService } from '../../users/services/users.service';
import { RouteRecommendationRequestDto } from '../dto/route-recommendation-request.dto';
import { RouteOption, toRouteOption } from '../models/route-option';
import { RouteRequestsRepository } from '../repositories/route-requests.repository';
import { IncidentFilterService } from './incident-filter.service';
import { NetworkGraphService } from './network-graph.service';
import { RouteComposerService } from './route-composer.service';
import { RouteScoringService } from './route-scoring.service';

export interface RecommendationResponse {
  options: RouteOption[];
  activeIncidentsConsidered: number;
}

const MAXIMUM_OPTIONS = 4;

@Injectable()
export class RecommendationService {
  private readonly logger = new Logger(RecommendationService.name);

  constructor(
    private readonly usersService: UsersService,
    private readonly transportsService: TransportsService,
    private readonly googleDirectionsService: GoogleDirectionsService,
    private readonly networkGraphService: NetworkGraphService,
    private readonly routeComposerService: RouteComposerService,
    private readonly incidentFilterService: IncidentFilterService,
    private readonly routeScoringService: RouteScoringService,
    private readonly incidentsService: IncidentsService,
    private readonly safetyService: SafetyService,
    private readonly routeRequestsRepository: RouteRequestsRepository,
  ) {}

  async recommend(
    userId: string,
    dto: RouteRecommendationRequestDto,
  ): Promise<RecommendationResponse> {
    const now = new Date();
    const origin: Coordinate = { lat: dto.origin.lat, lng: dto.origin.lng };
    const destination: Coordinate = {
      lat: dto.destination.lat,
      lng: dto.destination.lng,
    };
    const { priority, accessibility } = await this.resolvePreferences(
      userId,
      dto,
    );
    const [walkingRoute, drivingRoute, network, activeIncidents, riskZones] =
      await Promise.all([
        this.googleDirectionsService.getWalkingRoute(origin, destination),
        this.googleDirectionsService.getDrivingRoute(origin, destination),
        this.transportsService.getRoutableNetwork(),
        this.incidentsService.getActiveIncidents(),
        this.safetyService.getZonesActiveAt(now),
      ]);
    const rideCandidates = this.networkGraphService.findRideCandidates(
      origin,
      destination,
      network,
      accessibility,
      now,
    );
    let options = this.routeComposerService.compose({
      origin,
      destination,
      walkingRoute,
      drivingRoute,
      rideCandidates,
    });
    options = this.incidentFilterService.applyIncidents(
      options,
      activeIncidents,
    );
    options = this.routeScoringService.score(options, riskZones, priority);
    options = this.routeScoringService
      .sortByPriority(options, priority)
      .slice(0, MAXIMUM_OPTIONS);
    await this.saveRequestHistory(userId, origin, destination, priority);
    return {
      options: options.map((option, index) =>
        toRouteOption(option, `opt-${index + 1}`),
      ),
      activeIncidentsConsidered: activeIncidents.length,
    };
  }

  private async resolvePreferences(
    userId: string,
    dto: RouteRecommendationRequestDto,
  ): Promise<{
    priority: TravelPriority;
    accessibility: AccessibilityProfile;
  }> {
    if (dto.priority && dto.accessibility) {
      return { priority: dto.priority, accessibility: dto.accessibility };
    }
    const profile = await this.usersService
      .getProfile(userId)
      .catch(() => null);
    return {
      priority: dto.priority ?? profile?.defaultPriority ?? TravelPriority.Time,
      accessibility:
        dto.accessibility ??
        profile?.accessibilityProfile ??
        AccessibilityProfile.None,
    };
  }

  private async saveRequestHistory(
    userId: string,
    origin: Coordinate,
    destination: Coordinate,
    priority: TravelPriority,
  ): Promise<void> {
    try {
      await this.routeRequestsRepository.save(
        userId,
        origin,
        destination,
        priority,
      );
    } catch (error) {
      this.logger.warn(
        `No se pudo guardar el histórico de la solicitud: ${(error as Error).message}`,
      );
    }
  }
}
