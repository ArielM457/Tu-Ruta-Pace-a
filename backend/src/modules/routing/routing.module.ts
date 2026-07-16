import { Module } from '@nestjs/common';
import { GoogleMapsModule } from '../../integrations/google-maps/google-maps.module';
import { IncidentsModule } from '../incidents/incidents.module';
import { SafetyModule } from '../safety/safety.module';
import { TransportsModule } from '../transports/transports.module';
import { UsersModule } from '../users/users.module';
import { RoutingController } from './controllers/routing.controller';
import { RouteRequestsRepository } from './repositories/route-requests.repository';
import { IncidentFilterService } from './services/incident-filter.service';
import { NetworkGraphService } from './services/network-graph.service';
import { RecommendationService } from './services/recommendation.service';
import { RouteComposerService } from './services/route-composer.service';
import { RouteScoringService } from './services/route-scoring.service';

@Module({
  imports: [
    GoogleMapsModule,
    TransportsModule,
    IncidentsModule,
    SafetyModule,
    UsersModule,
  ],
  controllers: [RoutingController],
  providers: [
    RecommendationService,
    NetworkGraphService,
    RouteComposerService,
    IncidentFilterService,
    RouteScoringService,
    RouteRequestsRepository,
  ],
  exports: [RecommendationService],
})
export class RoutingModule {}
