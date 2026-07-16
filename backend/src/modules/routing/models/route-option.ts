import { Coordinate, TransportMode } from '../../../common/types/domain';

export interface StopSummary {
  id: string;
  name: string;
}

export interface RouteLeg {
  mode: TransportMode;
  durationMinutes: number;
  distanceMeters: number;
  costBs: number;
  polyline: string;
  instruction: string;
  lineId?: string;
  lineName?: string;
  lineColor?: string;
  boardStop?: StopSummary;
  alightStop?: StopSummary;
}

export interface RouteOption {
  id: string;
  totalDurationMinutes: number;
  totalDistanceMeters: number;
  totalCostBs: number;
  safetyScore: number;
  avoidsIncidents: string[];
  legs: RouteLeg[];
}

export interface ComposedLeg extends RouteLeg {
  waypoints: Coordinate[];
}

export interface ComposedOption {
  legs: ComposedLeg[];
  totalDurationMinutes: number;
  totalDistanceMeters: number;
  totalCostBs: number;
  safetyScore: number;
  avoidsIncidents: string[];
}

export function recalculateTotals(option: ComposedOption): void {
  option.totalDurationMinutes = option.legs.reduce(
    (total, leg) => total + leg.durationMinutes,
    0,
  );
  option.totalDistanceMeters = option.legs.reduce(
    (total, leg) => total + leg.distanceMeters,
    0,
  );
  option.totalCostBs =
    Math.round(option.legs.reduce((total, leg) => total + leg.costBs, 0) * 10) /
    10;
}

export function toRouteOption(
  option: ComposedOption,
  optionId: string,
): RouteOption {
  return {
    id: optionId,
    totalDurationMinutes: option.totalDurationMinutes,
    totalDistanceMeters: option.totalDistanceMeters,
    totalCostBs: option.totalCostBs,
    safetyScore: option.safetyScore,
    avoidsIncidents: option.avoidsIncidents,
    legs: option.legs.map(({ waypoints: _waypoints, ...leg }) => leg),
  };
}
