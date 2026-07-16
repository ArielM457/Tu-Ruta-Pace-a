import { Injectable } from '@nestjs/common';
import {
  Coordinate,
  TransportKind,
  TransportMode,
} from '../../../common/types/domain';
import { haversineMeters } from '../../../common/utils/geo';
import { encodePolyline } from '../../../common/utils/polyline';
import { SurfaceRoute } from '../../../integrations/google-maps/google-directions.service';
import {
  ComposedLeg,
  ComposedOption,
  recalculateTotals,
} from '../models/route-option';
import { RideCandidate, RideSegment } from './network-graph.service';

export interface CompositionInput {
  origin: Coordinate;
  destination: Coordinate;
  walkingRoute: SurfaceRoute;
  drivingRoute: SurfaceRoute;
  rideCandidates: RideCandidate[];
}

const WALKING_ONLY_MAXIMUM_METERS = 2000;
const NEGLIGIBLE_WALK_METERS = 40;
const WALKING_SPEED_KMH = 4.5;
const WALK_DETOUR_FACTOR = 1.3;
const TAXI_BASE_FARE_BS = 6;
const TAXI_FARE_PER_KM_BS = 2.5;
const MINIBUS_DURATION_FACTOR = 1.6;
const MINIBUS_FARE_BS = 2.4;

const MODE_BY_KIND: Partial<Record<TransportKind, TransportMode>> = {
  [TransportKind.CableCar]: TransportMode.CableCar,
  [TransportKind.Pumakatari]: TransportMode.Pumakatari,
  [TransportKind.Minibus]: TransportMode.Minibus,
  [TransportKind.Micro]: TransportMode.Micro,
  [TransportKind.Trufi]: TransportMode.Trufi,
};

@Injectable()
export class RouteComposerService {
  compose(input: CompositionInput): ComposedOption[] {
    const options: ComposedOption[] = [];
    for (const candidate of input.rideCandidates) {
      options.push(this.composeNetworkOption(input, candidate));
    }
    options.push(this.composeTaxiOption(input));
    options.push(this.composeMinibusOption(input));
    if (input.walkingRoute.distanceMeters <= WALKING_ONLY_MAXIMUM_METERS) {
      options.push(this.composeWalkingOption(input));
    }
    return options;
  }

  buildWalkLeg(
    from: Coordinate,
    to: Coordinate,
    instruction: string,
  ): ComposedLeg {
    const distanceMeters = Math.round(
      haversineMeters(from, to) * WALK_DETOUR_FACTOR,
    );
    const durationMinutes = Math.max(
      1,
      Math.round((distanceMeters / 1000 / WALKING_SPEED_KMH) * 60),
    );
    return {
      mode: TransportMode.Walk,
      durationMinutes,
      distanceMeters,
      costBs: 0,
      polyline: encodePolyline([from, to]),
      instruction,
      waypoints: [from, to],
    };
  }

  buildTaxiLeg(
    from: Coordinate,
    to: Coordinate,
    route: SurfaceRoute,
    instruction: string,
  ): ComposedLeg {
    return {
      mode: TransportMode.Taxi,
      durationMinutes: route.durationMinutes,
      distanceMeters: route.distanceMeters,
      costBs: this.taxiFareFor(route.distanceMeters),
      polyline: route.polyline,
      instruction,
      waypoints: [from, to],
    };
  }

  estimateTaxiLegBetween(from: Coordinate, to: Coordinate): ComposedLeg {
    const distanceMeters = Math.round(
      haversineMeters(from, to) * WALK_DETOUR_FACTOR,
    );
    const durationMinutes = Math.max(
      1,
      Math.round((distanceMeters / 1000 / 22) * 60),
    );
    return {
      mode: TransportMode.Taxi,
      durationMinutes,
      distanceMeters,
      costBs: this.taxiFareFor(distanceMeters),
      polyline: encodePolyline([from, to]),
      instruction: 'Toma un taxi seguro en este tramo',
      waypoints: [from, to],
    };
  }

  private composeNetworkOption(
    input: CompositionInput,
    candidate: RideCandidate,
  ): ComposedOption {
    const legs: ComposedLeg[] = [];
    const firstSegment = candidate.segments[0];
    this.appendWalkIfNeeded(
      legs,
      input.origin,
      firstSegment.boardStop,
      `Camina hasta ${firstSegment.boardStop.name}`,
    );
    candidate.segments.forEach((segment, index) => {
      if (index > 0) {
        const previousSegment = candidate.segments[index - 1];
        this.appendWalkIfNeeded(
          legs,
          previousSegment.alightStop,
          segment.boardStop,
          `Camina hasta ${segment.boardStop.name} para el transbordo`,
        );
      }
      legs.push(this.buildRideLeg(segment));
    });
    const lastSegment = candidate.segments[candidate.segments.length - 1];
    this.appendWalkIfNeeded(
      legs,
      lastSegment.alightStop,
      input.destination,
      'Camina hasta tu destino',
    );
    return this.finishOption(legs);
  }

  private composeTaxiOption(input: CompositionInput): ComposedOption {
    const legs = [
      this.buildTaxiLeg(
        input.origin,
        input.destination,
        input.drivingRoute,
        'Toma un taxi o radiotaxi hasta tu destino',
      ),
    ];
    return this.finishOption(legs);
  }

  private composeMinibusOption(input: CompositionInput): ComposedOption {
    const legs: ComposedLeg[] = [
      {
        mode: TransportMode.Minibus,
        durationMinutes: Math.round(
          input.drivingRoute.durationMinutes * MINIBUS_DURATION_FACTOR,
        ),
        distanceMeters: input.drivingRoute.distanceMeters,
        costBs: MINIBUS_FARE_BS,
        polyline: input.drivingRoute.polyline,
        instruction: 'Toma un minibús con dirección a tu destino',
        waypoints: [input.origin, input.destination],
      },
    ];
    return this.finishOption(legs);
  }

  private composeWalkingOption(input: CompositionInput): ComposedOption {
    const legs: ComposedLeg[] = [
      {
        mode: TransportMode.Walk,
        durationMinutes: input.walkingRoute.durationMinutes,
        distanceMeters: input.walkingRoute.distanceMeters,
        costBs: 0,
        polyline: input.walkingRoute.polyline,
        instruction: 'Camina hasta tu destino',
        waypoints: [input.origin, input.destination],
      },
    ];
    return this.finishOption(legs);
  }

  private buildRideLeg(segment: RideSegment): ComposedLeg {
    const mode = MODE_BY_KIND[segment.line.kind] ?? TransportMode.Minibus;
    return {
      mode,
      durationMinutes: segment.durationMinutes,
      distanceMeters: segment.distanceMeters,
      costBs: segment.line.fareBs,
      polyline: encodePolyline(segment.path),
      instruction: `Toma ${segment.line.name} desde ${segment.boardStop.name} hasta ${segment.alightStop.name}`,
      lineId: segment.line.id,
      lineName: segment.line.name,
      lineColor: segment.line.color ?? undefined,
      boardStop: { id: segment.boardStop.id, name: segment.boardStop.name },
      alightStop: { id: segment.alightStop.id, name: segment.alightStop.name },
      waypoints: segment.path,
    };
  }

  private appendWalkIfNeeded(
    legs: ComposedLeg[],
    from: Coordinate,
    to: Coordinate,
    instruction: string,
  ): void {
    if (haversineMeters(from, to) < NEGLIGIBLE_WALK_METERS) {
      return;
    }
    legs.push(this.buildWalkLeg(from, to, instruction));
  }

  private taxiFareFor(distanceMeters: number): number {
    const fare =
      TAXI_BASE_FARE_BS + (distanceMeters / 1000) * TAXI_FARE_PER_KM_BS;
    return Math.round(fare * 10) / 10;
  }

  private finishOption(legs: ComposedLeg[]): ComposedOption {
    const option: ComposedOption = {
      legs,
      totalDurationMinutes: 0,
      totalDistanceMeters: 0,
      totalCostBs: 0,
      safetyScore: 0,
      avoidsIncidents: [],
    };
    recalculateTotals(option);
    return option;
  }
}
