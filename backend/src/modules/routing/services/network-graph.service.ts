import { Injectable } from '@nestjs/common';
import {
  AccessibilityProfile,
  Coordinate,
  TransportKind,
} from '../../../common/types/domain';
import { haversineMeters, pathMeters } from '../../../common/utils/geo';
import {
  NetworkLine,
  TransportsService,
  TransportStop,
} from '../../transports/services/transports.service';

export interface RideSegment {
  line: NetworkLine;
  boardStop: TransportStop;
  alightStop: TransportStop;
  path: Coordinate[];
  distanceMeters: number;
  durationMinutes: number;
}

export interface RideCandidate {
  segments: RideSegment[];
}

const MAXIMUM_ACCESS_WALK_METERS = 1200;
const TRANSFER_RADIUS_METERS = 400;
const CABLE_CAR_SPEED_KMH = 18;
const PUMAKATARI_SPEED_KMH = 14;
const INTERMEDIATE_STOP_DWELL_MINUTES = 0.5;
const MAXIMUM_CANDIDATES = 3;

@Injectable()
export class NetworkGraphService {
  constructor(private readonly transportsService: TransportsService) {}

  findRideCandidates(
    origin: Coordinate,
    destination: Coordinate,
    network: NetworkLine[],
    accessibility: AccessibilityProfile,
    at: Date,
  ): RideCandidate[] {
    const operatingLines = network.filter((line) =>
      this.transportsService.isLineInService(line, at),
    );
    const direct = this.buildDirectCandidates(
      origin,
      destination,
      operatingLines,
      accessibility,
    );
    const withTransfer = this.buildTransferCandidates(
      origin,
      destination,
      operatingLines,
      accessibility,
    );
    return [...direct, ...withTransfer]
      .sort(
        (a, b) => this.candidateRideMinutes(a) - this.candidateRideMinutes(b),
      )
      .slice(0, MAXIMUM_CANDIDATES);
  }

  private buildDirectCandidates(
    origin: Coordinate,
    destination: Coordinate,
    lines: NetworkLine[],
    accessibility: AccessibilityProfile,
  ): RideCandidate[] {
    const candidates: RideCandidate[] = [];
    for (const line of lines) {
      const boardStop = this.nearestReachableStop(line, origin, accessibility);
      const alightStop = this.nearestReachableStop(
        line,
        destination,
        accessibility,
      );
      if (!boardStop || !alightStop || boardStop.id === alightStop.id) {
        continue;
      }
      candidates.push({
        segments: [this.buildSegment(line, boardStop, alightStop)],
      });
    }
    return candidates;
  }

  private buildTransferCandidates(
    origin: Coordinate,
    destination: Coordinate,
    lines: NetworkLine[],
    accessibility: AccessibilityProfile,
  ): RideCandidate[] {
    const candidates: RideCandidate[] = [];
    for (const firstLine of lines) {
      const boardStop = this.nearestReachableStop(
        firstLine,
        origin,
        accessibility,
      );
      if (!boardStop) {
        continue;
      }
      for (const secondLine of lines) {
        if (secondLine.id === firstLine.id) {
          continue;
        }
        const alightStop = this.nearestReachableStop(
          secondLine,
          destination,
          accessibility,
        );
        if (!alightStop) {
          continue;
        }
        const connection = this.findTransferConnection(
          firstLine,
          secondLine,
          accessibility,
        );
        if (!connection) {
          continue;
        }
        const [transferOut, transferIn] = connection;
        if (
          boardStop.id === transferOut.id ||
          alightStop.id === transferIn.id
        ) {
          continue;
        }
        candidates.push({
          segments: [
            this.buildSegment(firstLine, boardStop, transferOut),
            this.buildSegment(secondLine, transferIn, alightStop),
          ],
        });
      }
    }
    return candidates;
  }

  private findTransferConnection(
    firstLine: NetworkLine,
    secondLine: NetworkLine,
    accessibility: AccessibilityProfile,
  ): [TransportStop, TransportStop] | null {
    let best: [TransportStop, TransportStop] | null = null;
    let bestDistance = Number.POSITIVE_INFINITY;
    for (const firstStop of this.usableStops(firstLine, accessibility)) {
      for (const secondStop of this.usableStops(secondLine, accessibility)) {
        const distance = haversineMeters(firstStop, secondStop);
        if (distance <= TRANSFER_RADIUS_METERS && distance < bestDistance) {
          best = [firstStop, secondStop];
          bestDistance = distance;
        }
      }
    }
    return best;
  }

  private nearestReachableStop(
    line: NetworkLine,
    point: Coordinate,
    accessibility: AccessibilityProfile,
  ): TransportStop | null {
    let nearest: TransportStop | null = null;
    let nearestDistance = Number.POSITIVE_INFINITY;
    for (const stop of this.usableStops(line, accessibility)) {
      const distance = haversineMeters(point, stop);
      if (
        distance <= MAXIMUM_ACCESS_WALK_METERS &&
        distance < nearestDistance
      ) {
        nearest = stop;
        nearestDistance = distance;
      }
    }
    return nearest;
  }

  private usableStops(
    line: NetworkLine,
    accessibility: AccessibilityProfile,
  ): TransportStop[] {
    if (accessibility !== AccessibilityProfile.ReducedMobility) {
      return line.stops;
    }
    return line.stops.filter((stop) => stop.isAccessible);
  }

  private buildSegment(
    line: NetworkLine,
    boardStop: TransportStop,
    alightStop: TransportStop,
  ): RideSegment {
    const path = this.stopsBetween(line, boardStop, alightStop).map((stop) => ({
      lat: stop.lat,
      lng: stop.lng,
    }));
    const distanceMeters = pathMeters(path);
    const speedKmh =
      line.kind === TransportKind.CableCar
        ? CABLE_CAR_SPEED_KMH
        : PUMAKATARI_SPEED_KMH;
    const rideMinutes = (distanceMeters / 1000 / speedKmh) * 60;
    const dwellMinutes =
      Math.max(0, path.length - 2) * INTERMEDIATE_STOP_DWELL_MINUTES;
    return {
      line,
      boardStop,
      alightStop,
      path,
      distanceMeters,
      durationMinutes: Math.max(1, Math.round(rideMinutes + dwellMinutes)),
    };
  }

  private stopsBetween(
    line: NetworkLine,
    from: TransportStop,
    to: TransportStop,
  ): TransportStop[] {
    const ascending = from.sequence <= to.sequence;
    const [lower, upper] = ascending
      ? [from.sequence, to.sequence]
      : [to.sequence, from.sequence];
    const slice = line.stops.filter(
      (stop) => stop.sequence >= lower && stop.sequence <= upper,
    );
    return ascending ? slice : [...slice].reverse();
  }

  private candidateRideMinutes(candidate: RideCandidate): number {
    return candidate.segments.reduce(
      (total, segment) => total + segment.durationMinutes,
      0,
    );
  }
}
