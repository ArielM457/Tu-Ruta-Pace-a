import { Injectable } from '@nestjs/common';
import { TransportMode } from '../../../common/types/domain';
import { haversineMeters } from '../../../common/utils/geo';
import { Incident } from '../../incidents/services/incidents.service';
import { ComposedOption, recalculateTotals } from '../models/route-option';

const INCIDENT_PROXIMITY_METERS = 150;
const AFFECTED_LEG_DURATION_FACTOR = 1.8;

@Injectable()
export class IncidentFilterService {
  applyIncidents(
    options: ComposedOption[],
    incidents: Incident[],
  ): ComposedOption[] {
    const affectedIdsByOption = options.map((option) =>
      this.penalizeAffectedLegs(option, incidents),
    );
    const allAffectedIds = new Set(affectedIdsByOption.flat());
    options.forEach((option, index) => {
      const ownAffected = new Set(affectedIdsByOption[index]);
      option.avoidsIncidents = [...allAffectedIds].filter(
        (incidentId) => !ownAffected.has(incidentId),
      );
    });
    return options;
  }

  private penalizeAffectedLegs(
    option: ComposedOption,
    incidents: Incident[],
  ): string[] {
    const affectedIds = new Set<string>();
    for (const leg of option.legs) {
      if (leg.mode === TransportMode.CableCar) {
        continue;
      }
      const legIncidents = incidents.filter((incident) =>
        leg.waypoints.some(
          (waypoint) =>
            haversineMeters(waypoint, incident.position) <=
            INCIDENT_PROXIMITY_METERS,
        ),
      );
      if (legIncidents.length === 0) {
        continue;
      }
      leg.durationMinutes = Math.round(
        leg.durationMinutes * AFFECTED_LEG_DURATION_FACTOR,
      );
      legIncidents.forEach((incident) => affectedIds.add(incident.id));
    }
    if (affectedIds.size > 0) {
      recalculateTotals(option);
    }
    return [...affectedIds];
  }
}
