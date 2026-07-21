import { HttpStatus, Injectable } from '@nestjs/common';
import { DomainException } from '../../../common/exceptions/domain.exception';
import { Coordinate } from '../../../common/types/domain';
import { haversineMeters, midpoint } from '../../../common/utils/geo';
import { GoogleDirectionsService } from '../../../integrations/google-maps/google-directions.service';
import {
  Incident,
  IncidentsService,
} from '../../incidents/services/incidents.service';
import {
  HealthFacilitiesRepository,
  HealthFacilityRecord,
} from '../repositories/health-facilities.repository';

export interface EmergencyContact {
  name: string;
  number: string;
}

export interface HealthFacility {
  id: string;
  name: string;
  kind: string;
  position: Coordinate;
  phone: string | null;
}

export interface EmergencyRouteCandidate {
  facility: HealthFacility;
  durationMinutes: number;
  distanceMeters: number;
  polyline: string;
  affectedByIncidents: boolean;
}

export interface EmergencyRouteResponse {
  recommended: EmergencyRouteCandidate;
  alternatives: EmergencyRouteCandidate[];
}

export const LA_PAZ_EMERGENCY_CONTACTS: EmergencyContact[] = [
  { name: 'Policía Nacional', number: '110' },
  { name: 'Bomberos', number: '119' },
  { name: 'Ambulancia SAMU', number: '165' },
  { name: 'Defensa Civil', number: '800-10-1900' },
  { name: 'Hospital de Clínicas', number: '2-283-5959' },
  { name: 'Línea de Seguridad', number: '800-14-0000' },
];

const HOSPITALS_TO_EVALUATE = 4;
const FACILITIES_DEFAULT_RADIUS_METERS = 1500;
const INCIDENT_PROXIMITY_METERS = 300;
const INCIDENT_DURATION_FACTOR = 1.5;

@Injectable()
export class EmergencyService {
  constructor(
    private readonly healthFacilitiesRepository: HealthFacilitiesRepository,
    private readonly googleDirectionsService: GoogleDirectionsService,
    private readonly incidentsService: IncidentsService,
  ) {}

  getContacts(): EmergencyContact[] {
    return LA_PAZ_EMERGENCY_CONTACTS;
  }

  async findFacilitiesNear(
    point: Coordinate,
    radiusMeters?: number,
    kind?: string,
  ): Promise<HealthFacility[]> {
    const radius = radiusMeters ?? FACILITIES_DEFAULT_RADIUS_METERS;
    const records = kind
      ? await this.healthFacilitiesRepository.findByKind(kind)
      : await this.healthFacilitiesRepository.findAll();
    return records
      .map((record) => this.toFacility(record))
      .filter(
        (facility) => haversineMeters(point, facility.position) <= radius,
      );
  }

  async buildEmergencyRoute(
    origin: Coordinate,
  ): Promise<EmergencyRouteResponse> {
    const hospitals =
      await this.healthFacilitiesRepository.findByKind('hospital');
    if (hospitals.length === 0) {
      throw new DomainException(
        'NO_HOSPITALS_AVAILABLE',
        'No hay hospitales registrados en el sistema',
        HttpStatus.SERVICE_UNAVAILABLE,
      );
    }
    const activeIncidents = await this.incidentsService.getActiveIncidents();
    const nearestHospitals = hospitals
      .map((record) => this.toFacility(record))
      .sort(
        (a, b) =>
          haversineMeters(origin, a.position) -
          haversineMeters(origin, b.position),
      )
      .slice(0, HOSPITALS_TO_EVALUATE);
    const candidates = await Promise.all(
      nearestHospitals.map((facility) =>
        this.evaluateCandidate(origin, facility, activeIncidents),
      ),
    );
    candidates.sort((a, b) => a.durationMinutes - b.durationMinutes);
    const [recommended, ...alternatives] = candidates;
    return { recommended, alternatives };
  }

  private async evaluateCandidate(
    origin: Coordinate,
    facility: HealthFacility,
    activeIncidents: Incident[],
  ): Promise<EmergencyRouteCandidate> {
    const route = await this.googleDirectionsService.getDrivingRoute(
      origin,
      facility.position,
    );
    const affectedByIncidents = this.isPathNearAnyIncident(
      origin,
      facility.position,
      activeIncidents,
    );
    const durationMinutes = affectedByIncidents
      ? Math.round(route.durationMinutes * INCIDENT_DURATION_FACTOR)
      : route.durationMinutes;
    return {
      facility,
      durationMinutes,
      distanceMeters: route.distanceMeters,
      polyline: route.polyline,
      affectedByIncidents,
    };
  }

  private isPathNearAnyIncident(
    origin: Coordinate,
    destination: Coordinate,
    incidents: Incident[],
  ): boolean {
    const samplePoints = [origin, midpoint(origin, destination), destination];
    return incidents.some((incident) =>
      samplePoints.some(
        (point) =>
          haversineMeters(point, incident.position) <=
          INCIDENT_PROXIMITY_METERS,
      ),
    );
  }

  private toFacility(record: HealthFacilityRecord): HealthFacility {
    return {
      id: record.id,
      name: record.name,
      kind: record.kind,
      position: { lat: Number(record.lat), lng: Number(record.lng) },
      phone: record.phone,
    };
  }
}
