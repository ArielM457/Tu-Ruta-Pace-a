import { Injectable } from '@nestjs/common';
import { Coordinate } from '../../../common/types/domain';
import { haversineMeters } from '../../../common/utils/geo';
import { TransportsService } from '../../transports/services/transports.service';
import { VehicleQueryDto } from '../dto/vehicle-query.dto';
import { LocationPingsRepository } from '../repositories/location-pings.repository';
import { LocationSharesRepository } from '../repositories/location-shares.repository';
import { AyniPointsService, AyniReason } from './ayni-points.service';

export interface VehicleQueryResult {
  available: boolean;
  estimatedPosition: Coordinate | null;
  etaMinutes: number | null;
  activeCollaborators: number;
  pointsCharged: number;
  newBalance: number | null;
}

const RECENT_PING_WINDOW_MINUTES = 2;
const VEHICLE_AVERAGE_SPEED_KMH = 18;

@Injectable()
export class VehicleLocationService {
  constructor(
    private readonly locationSharesRepository: LocationSharesRepository,
    private readonly locationPingsRepository: LocationPingsRepository,
    private readonly transportsService: TransportsService,
    private readonly ayniPointsService: AyniPointsService,
  ) {}

  async queryVehicle(
    userId: string,
    dto: VehicleQueryDto,
  ): Promise<VehicleQueryResult> {
    const stop = await this.transportsService.getStop(dto.stopId);
    await this.transportsService.getLine(dto.lineId);
    const estimate = await this.estimateVehiclePosition(dto.lineId);
    if (!estimate) {
      return {
        available: false,
        estimatedPosition: null,
        etaMinutes: null,
        activeCollaborators: 0,
        pointsCharged: 0,
        newBalance: null,
      };
    }
    const newBalance = await this.ayniPointsService.charge(
      userId,
      this.ayniPointsService.queryCost,
      AyniReason.QueriedVehicle,
      dto.lineId,
    );
    const distanceToStop = haversineMeters(estimate.position, {
      lat: stop.lat,
      lng: stop.lng,
    });
    const etaMinutes = Math.max(
      1,
      Math.round((distanceToStop / 1000 / VEHICLE_AVERAGE_SPEED_KMH) * 60),
    );
    return {
      available: true,
      estimatedPosition: estimate.position,
      etaMinutes,
      activeCollaborators: estimate.collaborators,
      pointsCharged: this.ayniPointsService.queryCost,
      newBalance,
    };
  }

  private async estimateVehiclePosition(
    lineId: string,
  ): Promise<{ position: Coordinate; collaborators: number } | null> {
    const activeShares =
      await this.locationSharesRepository.findActiveByLine(lineId);
    if (activeShares.length === 0) {
      return null;
    }
    const since = new Date(
      Date.now() - RECENT_PING_WINDOW_MINUTES * 60 * 1000,
    ).toISOString();
    const recentPings = await this.locationPingsRepository.findRecentByShares(
      activeShares.map((share) => share.id),
      since,
    );
    if (recentPings.length === 0) {
      return null;
    }
    const latestPingByShare = new Map<string, Coordinate>();
    for (const ping of recentPings) {
      if (!latestPingByShare.has(ping.share_id)) {
        latestPingByShare.set(ping.share_id, {
          lat: Number(ping.lat),
          lng: Number(ping.lng),
        });
      }
    }
    const positions = [...latestPingByShare.values()];
    const averagePosition: Coordinate = {
      lat:
        positions.reduce((total, point) => total + point.lat, 0) /
        positions.length,
      lng:
        positions.reduce((total, point) => total + point.lng, 0) /
        positions.length,
    };
    return { position: averagePosition, collaborators: positions.length };
  }
}
