import { HttpStatus, Injectable } from '@nestjs/common';
import { DomainException } from '../../../common/exceptions/domain.exception';
import { TripStatus } from '../../../common/types/domain';
import { CreateTripDto } from '../dto/create-trip.dto';
import { TripRecord, TripsRepository } from '../repositories/trips.repository';

export interface Trip {
  id: string;
  userId: string;
  routeSnapshot: Record<string, unknown>;
  status: TripStatus;
  startedAt: string;
  finishedAt: string | null;
}

@Injectable()
export class TripsService {
  constructor(private readonly tripsRepository: TripsRepository) {}

  async startTrip(userId: string, dto: CreateTripDto): Promise<Trip> {
    await this.tripsRepository.cancelActiveTrips(userId);
    const record = await this.tripsRepository.create(userId, dto.routeSnapshot);
    return this.toTrip(record);
  }

  async finishTrip(userId: string, tripId: string): Promise<Trip> {
    const trip = await this.getOwnedTrip(userId, tripId);
    if (trip.status !== TripStatus.Active) {
      throw new DomainException(
        'TRIP_NOT_ACTIVE',
        'El viaje ya fue finalizado o cancelado',
        HttpStatus.CONFLICT,
      );
    }
    const record = await this.tripsRepository.markFinished(tripId);
    return this.toTrip(record);
  }

  async getOwnedTrip(userId: string, tripId: string): Promise<Trip> {
    const record = await this.tripsRepository.findById(tripId);
    if (!record || record.user_id !== userId) {
      throw new DomainException(
        'TRIP_NOT_FOUND',
        'El viaje no existe',
        HttpStatus.NOT_FOUND,
      );
    }
    return this.toTrip(record);
  }

  async findActiveTrip(userId: string): Promise<Trip | null> {
    const record = await this.tripsRepository.findActiveByUser(userId);
    return record ? this.toTrip(record) : null;
  }

  private toTrip(record: TripRecord): Trip {
    return {
      id: record.id,
      userId: record.user_id,
      routeSnapshot: record.route_snapshot,
      status: record.status as TripStatus,
      startedAt: record.started_at,
      finishedAt: record.finished_at,
    };
  }
}
