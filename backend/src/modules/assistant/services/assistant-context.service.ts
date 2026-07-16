import { Injectable } from '@nestjs/common';
import { Coordinate } from '../../../common/types/domain';
import { haversineMeters } from '../../../common/utils/geo';
import { IncidentsService } from '../../incidents/services/incidents.service';
import { TransportsService } from '../../transports/services/transports.service';
import { TripsService } from '../../trips/services/trips.service';
import { SharedExperiencesRepository } from '../repositories/shared-experiences.repository';

const NEARBY_INCIDENTS_RADIUS_METERS = 2000;

@Injectable()
export class AssistantContextService {
  constructor(
    private readonly tripsService: TripsService,
    private readonly incidentsService: IncidentsService,
    private readonly transportsService: TransportsService,
    private readonly sharedExperiencesRepository: SharedExperiencesRepository,
  ) {}

  async buildContext(
    userId: string,
    tripId?: string,
    location?: Coordinate,
  ): Promise<Record<string, unknown>> {
    const now = new Date();
    const [activeTrip, incidents, lines, experiences] = await Promise.all([
      this.resolveTrip(userId, tripId),
      this.incidentsService.getActiveIncidents(),
      this.transportsService.listLines(),
      this.sharedExperiencesRepository.findRecent(),
    ]);
    const nearbyIncidents = location
      ? incidents.filter(
          (incident) =>
            haversineMeters(location, incident.position) <=
            NEARBY_INCIDENTS_RADIUS_METERS,
        )
      : incidents;
    const linesInService = lines.filter((line) =>
      this.transportsService.isLineInService(line, now),
    );
    return {
      currentTime: now.toISOString(),
      userLocation: location ?? null,
      activeTrip,
      nearbyIncidents,
      linesInService: linesInService.map((line) => ({
        id: line.id,
        kind: line.kind,
        name: line.name,
        fareBs: line.fareBs,
        serviceStart: line.serviceStart,
        serviceEnd: line.serviceEnd,
      })),
      communityExperiences: experiences.map((experience) => ({
        zone: experience.zone,
        timeSlot: experience.time_slot,
        content: experience.content,
      })),
    };
  }

  private async resolveTrip(
    userId: string,
    tripId?: string,
  ): Promise<Record<string, unknown> | null> {
    const trip = tripId
      ? await this.tripsService.getOwnedTrip(userId, tripId).catch(() => null)
      : await this.tripsService.findActiveTrip(userId);
    if (!trip) {
      return null;
    }
    return {
      id: trip.id,
      status: trip.status,
      startedAt: trip.startedAt,
      routeSnapshot: trip.routeSnapshot,
    };
  }
}
