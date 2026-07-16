import { Injectable } from '@nestjs/common';
import { Coordinate } from '../../../common/types/domain';
import { haversineMeters } from '../../../common/utils/geo';
import {
  RiskZoneRecord,
  RiskZonesRepository,
} from '../repositories/risk-zones.repository';

export interface RiskZone {
  id: string;
  name: string;
  center: Coordinate;
  radiusMeters: number;
  riskStart: string;
  riskEnd: string;
  level: string;
  source: string;
}

@Injectable()
export class SafetyService {
  constructor(private readonly riskZonesRepository: RiskZonesRepository) {}

  async getZonesActiveAt(at: Date): Promise<RiskZone[]> {
    const zones = await this.riskZonesRepository.findAll();
    return zones
      .map((zone) => this.toZone(zone))
      .filter((zone) => this.isZoneActiveAt(zone, at));
  }

  isPointInsideAnyZone(point: Coordinate, zones: RiskZone[]): boolean {
    return zones.some(
      (zone) => haversineMeters(point, zone.center) <= zone.radiusMeters,
    );
  }

  isZoneActiveAt(zone: RiskZone, at: Date): boolean {
    const minutesOfDay = at.getHours() * 60 + at.getMinutes();
    const start = this.parseTimeToMinutes(zone.riskStart);
    const end = this.parseTimeToMinutes(zone.riskEnd);
    if (start <= end) {
      return minutesOfDay >= start && minutesOfDay <= end;
    }
    return minutesOfDay >= start || minutesOfDay <= end;
  }

  private parseTimeToMinutes(time: string): number {
    const [hours, minutes] = time.split(':').map(Number);
    return hours * 60 + (minutes || 0);
  }

  private toZone(record: RiskZoneRecord): RiskZone {
    return {
      id: record.id,
      name: record.name,
      center: { lat: Number(record.lat), lng: Number(record.lng) },
      radiusMeters: Number(record.radius_meters),
      riskStart: record.risk_start,
      riskEnd: record.risk_end,
      level: record.level,
      source: record.source,
    };
  }
}
