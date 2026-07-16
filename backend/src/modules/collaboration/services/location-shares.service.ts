import { HttpStatus, Injectable } from '@nestjs/common';
import { DomainException } from '../../../common/exceptions/domain.exception';
import { TripStatus } from '../../../common/types/domain';
import { TransportsService } from '../../transports/services/transports.service';
import { TripsService } from '../../trips/services/trips.service';
import { RecordPingDto } from '../dto/record-ping.dto';
import { StartShareDto } from '../dto/start-share.dto';
import {
  LocationShareRecord,
  LocationSharesRepository,
} from '../repositories/location-shares.repository';
import { LocationPingsRepository } from '../repositories/location-pings.repository';
import { AyniPointsService, AyniReason } from './ayni-points.service';

export interface LocationShare {
  id: string;
  tripId: string;
  lineId: string;
  startedAt: string;
  endedAt: string | null;
  pointsAwarded: number | null;
}

const MILLISECONDS_PER_MINUTE = 60 * 1000;

@Injectable()
export class LocationSharesService {
  constructor(
    private readonly locationSharesRepository: LocationSharesRepository,
    private readonly locationPingsRepository: LocationPingsRepository,
    private readonly tripsService: TripsService,
    private readonly transportsService: TransportsService,
    private readonly ayniPointsService: AyniPointsService,
  ) {}

  async startShare(userId: string, dto: StartShareDto): Promise<LocationShare> {
    const trip = await this.tripsService.getOwnedTrip(userId, dto.tripId);
    if (trip.status !== TripStatus.Active) {
      throw new DomainException(
        'TRIP_NOT_ACTIVE',
        'Solo puedes compartir ubicación durante un viaje activo',
        HttpStatus.CONFLICT,
      );
    }
    await this.transportsService.getLine(dto.lineId);
    await this.locationSharesRepository.endActiveSharesForUser(userId);
    const record = await this.locationSharesRepository.create(
      userId,
      dto.tripId,
      dto.lineId,
    );
    return this.toShare(record);
  }

  async recordPing(
    userId: string,
    shareId: string,
    dto: RecordPingDto,
  ): Promise<void> {
    const share = await this.getOwnedActiveShare(userId, shareId);
    await this.locationPingsRepository.record(
      share.id,
      dto.lat,
      dto.lng,
      dto.recordedAt ?? new Date().toISOString(),
    );
  }

  async stopShare(
    userId: string,
    shareId: string,
  ): Promise<LocationShare & { newBalance: number }> {
    const share = await this.getOwnedActiveShare(userId, shareId);
    const endedAt = new Date();
    const sharedMinutes =
      (endedAt.getTime() - new Date(share.startedAt).getTime()) /
      MILLISECONDS_PER_MINUTE;
    const pointsEarned =
      this.ayniPointsService.pointsForSharedMinutes(sharedMinutes);
    const closed = await this.locationSharesRepository.closeShare(
      share.id,
      endedAt.toISOString(),
      pointsEarned,
    );
    const newBalance = await this.ayniPointsService.award(
      userId,
      pointsEarned,
      AyniReason.SharedLocation,
      share.id,
    );
    return { ...this.toShare(closed), newBalance };
  }

  private async getOwnedActiveShare(
    userId: string,
    shareId: string,
  ): Promise<LocationShare> {
    const record = await this.locationSharesRepository.findById(shareId);
    if (!record || record.user_id !== userId) {
      throw new DomainException(
        'SHARE_NOT_FOUND',
        'La sesión de ubicación compartida no existe',
        HttpStatus.NOT_FOUND,
      );
    }
    if (record.ended_at) {
      throw new DomainException(
        'SHARE_ALREADY_ENDED',
        'Esta sesión de ubicación compartida ya terminó',
        HttpStatus.CONFLICT,
      );
    }
    return this.toShare(record);
  }

  private toShare(record: LocationShareRecord): LocationShare {
    return {
      id: record.id,
      tripId: record.trip_id,
      lineId: record.line_id,
      startedAt: record.started_at,
      endedAt: record.ended_at,
      pointsAwarded: record.points_awarded,
    };
  }
}
