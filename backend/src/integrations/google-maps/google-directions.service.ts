import { HttpService } from '@nestjs/axios';
import { Injectable, Logger } from '@nestjs/common';
import { firstValueFrom } from 'rxjs';
import { Coordinate } from '../../common/types/domain';
import { haversineMeters } from '../../common/utils/geo';
import { encodePolyline } from '../../common/utils/polyline';
import { AppConfigService } from '../../config/app-config.service';

export interface SurfaceRoute {
  durationMinutes: number;
  distanceMeters: number;
  polyline: string;
  usedFallbackEstimate: boolean;
}

interface DirectionsApiResponse {
  routes?: Array<{
    overview_polyline?: { points?: string };
    legs?: Array<{
      duration?: { value: number };
      duration_in_traffic?: { value: number };
      distance?: { value: number };
    }>;
  }>;
}

const DIRECTIONS_API_URL =
  'https://maps.googleapis.com/maps/api/directions/json';
const WALKING_SPEED_KMH = 4.5;
const DRIVING_SPEED_KMH = 22;
const ROAD_DISTANCE_FACTOR = 1.35;

@Injectable()
export class GoogleDirectionsService {
  private readonly logger = new Logger(GoogleDirectionsService.name);

  constructor(
    private readonly httpService: HttpService,
    private readonly appConfig: AppConfigService,
  ) {}

  async getWalkingRoute(
    origin: Coordinate,
    destination: Coordinate,
  ): Promise<SurfaceRoute> {
    return this.getRoute(origin, destination, 'walking', WALKING_SPEED_KMH);
  }

  async getDrivingRoute(
    origin: Coordinate,
    destination: Coordinate,
  ): Promise<SurfaceRoute> {
    return this.getRoute(origin, destination, 'driving', DRIVING_SPEED_KMH);
  }

  private async getRoute(
    origin: Coordinate,
    destination: Coordinate,
    mode: 'walking' | 'driving',
    fallbackSpeedKmh: number,
  ): Promise<SurfaceRoute> {
    const apiKey = this.appConfig.googleMapsApiKey;
    if (!apiKey) {
      return this.estimateRoute(origin, destination, fallbackSpeedKmh);
    }
    try {
      const response = await firstValueFrom(
        this.httpService.get<DirectionsApiResponse>(DIRECTIONS_API_URL, {
          params: {
            origin: `${origin.lat},${origin.lng}`,
            destination: `${destination.lat},${destination.lng}`,
            mode,
            departure_time: 'now',
            key: apiKey,
          },
        }),
      );
      const route = response.data.routes?.[0];
      const leg = route?.legs?.[0];
      if (!leg?.distance || !leg.duration) {
        return this.estimateRoute(origin, destination, fallbackSpeedKmh);
      }
      const durationSeconds =
        leg.duration_in_traffic?.value ?? leg.duration.value;
      return {
        durationMinutes: Math.max(1, Math.round(durationSeconds / 60)),
        distanceMeters: leg.distance.value,
        polyline:
          route?.overview_polyline?.points ??
          encodePolyline([origin, destination]),
        usedFallbackEstimate: false,
      };
    } catch (error) {
      this.logger.warn(
        `Google Directions falló, usando estimación local: ${(error as Error).message}`,
      );
      return this.estimateRoute(origin, destination, fallbackSpeedKmh);
    }
  }

  private estimateRoute(
    origin: Coordinate,
    destination: Coordinate,
    speedKmh: number,
  ): SurfaceRoute {
    const distanceMeters = Math.round(
      haversineMeters(origin, destination) * ROAD_DISTANCE_FACTOR,
    );
    const durationMinutes = Math.max(
      1,
      Math.round((distanceMeters / 1000 / speedKmh) * 60),
    );
    return {
      durationMinutes,
      distanceMeters,
      polyline: encodePolyline([origin, destination]),
      usedFallbackEstimate: true,
    };
  }
}
