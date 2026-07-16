import { Injectable } from '@nestjs/common';
import { TransportMode, TravelPriority } from '../../../common/types/domain';
import { RiskZone, SafetyService } from '../../safety/services/safety.service';
import {
  ComposedLeg,
  ComposedOption,
  recalculateTotals,
} from '../models/route-option';
import { RouteComposerService } from './route-composer.service';

const MODE_SAFETY_SCORE: Record<TransportMode, number> = {
  [TransportMode.CableCar]: 0.95,
  [TransportMode.Taxi]: 0.9,
  [TransportMode.Pumakatari]: 0.85,
  [TransportMode.Minibus]: 0.75,
  [TransportMode.Micro]: 0.75,
  [TransportMode.Trufi]: 0.75,
  [TransportMode.Walk]: 0.7,
};

const RISKY_WALK_SCORE = 0.4;

@Injectable()
export class RouteScoringService {
  constructor(
    private readonly safetyService: SafetyService,
    private readonly routeComposer: RouteComposerService,
  ) {}

  score(
    options: ComposedOption[],
    activeRiskZones: RiskZone[],
    priority: TravelPriority,
  ): ComposedOption[] {
    const scored = options.map((option) => {
      if (priority === TravelPriority.Safety) {
        this.replaceRiskyWalkLegsWithTaxi(option, activeRiskZones);
      }
      option.safetyScore = this.computeSafetyScore(option, activeRiskZones);
      return option;
    });
    return scored;
  }

  sortByPriority(
    options: ComposedOption[],
    priority: TravelPriority,
  ): ComposedOption[] {
    const sorted = [...options];
    if (priority === TravelPriority.Cost) {
      sorted.sort((a, b) => a.totalCostBs - b.totalCostBs);
      return sorted;
    }
    if (priority === TravelPriority.Safety) {
      sorted.sort((a, b) => b.safetyScore - a.safetyScore);
      return sorted;
    }
    sorted.sort((a, b) => a.totalDurationMinutes - b.totalDurationMinutes);
    return sorted;
  }

  private computeSafetyScore(
    option: ComposedOption,
    activeRiskZones: RiskZone[],
  ): number {
    if (option.totalDurationMinutes === 0) {
      return 1;
    }
    const weightedSum = option.legs.reduce(
      (total, leg) =>
        total + this.legSafetyScore(leg, activeRiskZones) * leg.durationMinutes,
      0,
    );
    const score = weightedSum / option.totalDurationMinutes;
    return Math.round(score * 100) / 100;
  }

  private legSafetyScore(
    leg: ComposedLeg,
    activeRiskZones: RiskZone[],
  ): number {
    const baseScore = MODE_SAFETY_SCORE[leg.mode];
    if (leg.mode !== TransportMode.Walk) {
      return baseScore;
    }
    const crossesRiskZone = leg.waypoints.some((waypoint) =>
      this.safetyService.isPointInsideAnyZone(waypoint, activeRiskZones),
    );
    return crossesRiskZone ? RISKY_WALK_SCORE : baseScore;
  }

  private replaceRiskyWalkLegsWithTaxi(
    option: ComposedOption,
    activeRiskZones: RiskZone[],
  ): void {
    let replaced = false;
    option.legs = option.legs.map((leg) => {
      if (leg.mode !== TransportMode.Walk) {
        return leg;
      }
      const crossesRiskZone = leg.waypoints.some((waypoint) =>
        this.safetyService.isPointInsideAnyZone(waypoint, activeRiskZones),
      );
      if (!crossesRiskZone) {
        return leg;
      }
      replaced = true;
      const from = leg.waypoints[0];
      const to = leg.waypoints[leg.waypoints.length - 1];
      return this.routeComposer.estimateTaxiLegBetween(from, to);
    });
    if (replaced) {
      recalculateTotals(option);
    }
  }
}
