import { Injectable } from '@nestjs/common';
import {
  Coordinate,
  IncidentKind,
  IncidentSource,
  IncidentStatus,
  IncidentVote,
} from '../../../common/types/domain';
import { haversineMeters } from '../../../common/utils/geo';
import { AppConfigService } from '../../../config/app-config.service';
import {
  AyniPointsService,
  AyniReason,
} from '../../collaboration/services/ayni-points.service';
import { CreateIncidentDto } from '../dto/create-incident.dto';
import { CreateOfficialClosureDto } from '../dto/create-official-closure.dto';
import {
  IncidentRecord,
  IncidentSearchFilters,
  IncidentsRepository,
} from '../repositories/incidents.repository';

export interface Incident {
  id: string;
  kind: IncidentKind;
  source: IncidentSource;
  status: IncidentStatus;
  position: Coordinate;
  description: string;
  photoUrl: string | null;
  confirmations: number;
  denials: number;
  startsAt: string;
  expiresAt: string;
  createdAt: string;
}

const DUPLICATE_RADIUS_METERS = 100;
const PENDING_NEAR_DEFAULT_RADIUS_METERS = 800;
const BLOCKADE_LIFETIME_HOURS = 12;
const ROADWORK_LIFETIME_DAYS = 7;
const OFFICIAL_CLOSURE_DEFAULT_DAYS = 3;

@Injectable()
export class IncidentsService {
  constructor(
    private readonly incidentsRepository: IncidentsRepository,
    private readonly ayniPointsService: AyniPointsService,
    private readonly appConfig: AppConfigService,
  ) {}

  async reportIncident(
    userId: string,
    dto: CreateIncidentDto,
  ): Promise<Incident> {
    const duplicate = await this.findNearbyDuplicate(dto.kind, dto.position);
    if (duplicate) {
      return this.confirmInsteadOfDuplicating(duplicate, userId);
    }
    const now = new Date();
    const record = await this.incidentsRepository.create({
      reporter_id: userId,
      kind: dto.kind,
      source: IncidentSource.Citizen,
      status: IncidentStatus.Pending,
      lat: dto.position.lat,
      lng: dto.position.lng,
      description: dto.description,
      photo_url: dto.photoUrl ?? null,
      starts_at: now.toISOString(),
      expires_at: this.lifetimeFor(dto.kind, now).toISOString(),
    });
    return this.toIncident(record);
  }

  async createOfficialClosure(
    userId: string,
    dto: CreateOfficialClosureDto,
  ): Promise<Incident> {
    const now = new Date();
    const startsAt = dto.startsAt ? new Date(dto.startsAt) : now;
    const expiresAt = dto.expiresAt
      ? new Date(dto.expiresAt)
      : this.addDays(startsAt, OFFICIAL_CLOSURE_DEFAULT_DAYS);
    const record = await this.incidentsRepository.create({
      reporter_id: userId,
      kind: IncidentKind.OfficialClosure,
      source: IncidentSource.Official,
      status: IncidentStatus.Active,
      lat: dto.position.lat,
      lng: dto.position.lng,
      description: dto.description,
      photo_url: null,
      starts_at: startsAt.toISOString(),
      expires_at: expiresAt.toISOString(),
    });
    return this.toIncident(record);
  }

  async voteIncident(
    incidentId: string,
    userId: string,
    vote: IncidentVote,
  ): Promise<Incident> {
    const record = await this.incidentsRepository.registerVote(
      incidentId,
      userId,
      vote,
      this.appConfig.incidentConfirmThreshold,
      this.appConfig.incidentResolveThreshold,
    );
    await this.rewardReporterIfJustVerified(record);
    return this.toIncident(record);
  }

  private async rewardReporterIfJustVerified(
    record: IncidentRecord,
  ): Promise<void> {
    const isVerifiedCitizenReport =
      record.status === IncidentStatus.Active &&
      record.source === IncidentSource.Citizen &&
      record.reporter_id !== null;
    if (!isVerifiedCitizenReport) {
      return;
    }
    await this.ayniPointsService.awardOncePerReference(
      record.reporter_id as string,
      this.appConfig.ayniVerifiedReportReward,
      AyniReason.VerifiedReport,
      record.id,
    );
  }

  async getActiveIncidents(bbox?: string): Promise<Incident[]> {
    const records = await this.incidentsRepository.findByStatuses([
      IncidentStatus.Active,
    ]);
    const incidents = records.map((record) => this.toIncident(record));
    if (!bbox) {
      return incidents;
    }
    const [minLng, minLat, maxLng, maxLat] = bbox.split(',').map(Number);
    return incidents.filter(
      (incident) =>
        incident.position.lng >= minLng &&
        incident.position.lng <= maxLng &&
        incident.position.lat >= minLat &&
        incident.position.lat <= maxLat,
    );
  }

  async getPendingIncidentsNear(
    point: Coordinate,
    radiusMeters?: number,
  ): Promise<Incident[]> {
    const radius = radiusMeters ?? PENDING_NEAR_DEFAULT_RADIUS_METERS;
    const records = await this.incidentsRepository.findByStatuses([
      IncidentStatus.Pending,
    ]);
    return records
      .map((record) => this.toIncident(record))
      .filter(
        (incident) => haversineMeters(point, incident.position) <= radius,
      );
  }

  async searchIncidents(filters: IncidentSearchFilters): Promise<Incident[]> {
    const records = await this.incidentsRepository.search(filters);
    return records.map((record) => this.toIncident(record));
  }

  private async findNearbyDuplicate(
    kind: IncidentKind,
    position: Coordinate,
  ): Promise<Incident | null> {
    const records = await this.incidentsRepository.findByStatuses([
      IncidentStatus.Pending,
      IncidentStatus.Active,
    ]);
    const duplicate = records
      .map((record) => this.toIncident(record))
      .find(
        (incident) =>
          incident.kind === kind &&
          haversineMeters(position, incident.position) <=
            DUPLICATE_RADIUS_METERS,
      );
    return duplicate ?? null;
  }

  private async confirmInsteadOfDuplicating(
    duplicate: Incident,
    userId: string,
  ): Promise<Incident> {
    try {
      return await this.voteIncident(
        duplicate.id,
        userId,
        IncidentVote.Confirm,
      );
    } catch {
      return duplicate;
    }
  }

  private lifetimeFor(kind: IncidentKind, from: Date): Date {
    if (kind === IncidentKind.Roadwork) {
      return this.addDays(from, ROADWORK_LIFETIME_DAYS);
    }
    return new Date(from.getTime() + BLOCKADE_LIFETIME_HOURS * 60 * 60 * 1000);
  }

  private addDays(from: Date, days: number): Date {
    return new Date(from.getTime() + days * 24 * 60 * 60 * 1000);
  }

  private toIncident(record: IncidentRecord): Incident {
    return {
      id: record.id,
      kind: record.kind as IncidentKind,
      source: record.source as IncidentSource,
      status: record.status as IncidentStatus,
      position: { lat: Number(record.lat), lng: Number(record.lng) },
      description: record.description,
      photoUrl: record.photo_url,
      confirmations: record.confirmations,
      denials: record.denials,
      startsAt: record.starts_at,
      expiresAt: record.expires_at,
      createdAt: record.created_at,
    };
  }
}
