import { Injectable } from '@nestjs/common';
import {
  Incident,
  IncidentsService,
} from '../../incidents/services/incidents.service';
import {
  CongestionSummaryQueryDto,
  GovernmentIncidentsQueryDto,
} from '../dto/government-queries.dto';

export interface CongestionSummary {
  totalIncidents: number;
  byKind: Record<string, number>;
  byStatus: Record<string, number>;
  bySource: Record<string, number>;
  dailySeries: Array<{ date: string; count: number }>;
}

const DEFAULT_SUMMARY_DAYS = 7;

@Injectable()
export class GovernmentService {
  constructor(private readonly incidentsService: IncidentsService) {}

  async buildCongestionSummary(
    query: CongestionSummaryQueryDto,
  ): Promise<CongestionSummary> {
    const from =
      query.from ??
      new Date(
        Date.now() - DEFAULT_SUMMARY_DAYS * 24 * 60 * 60 * 1000,
      ).toISOString();
    const incidents = await this.incidentsService.searchIncidents({
      from,
      to: query.to,
    });
    return {
      totalIncidents: incidents.length,
      byKind: this.countBy(incidents, (incident) => incident.kind),
      byStatus: this.countBy(incidents, (incident) => incident.status),
      bySource: this.countBy(incidents, (incident) => incident.source),
      dailySeries: this.buildDailySeries(incidents),
    };
  }

  async listIncidents(query: GovernmentIncidentsQueryDto): Promise<Incident[]> {
    return this.incidentsService.searchIncidents({
      statuses: query.status ? [query.status] : undefined,
      kind: query.kind,
      from: query.from,
      to: query.to,
    });
  }

  private countBy(
    incidents: Incident[],
    selector: (incident: Incident) => string,
  ): Record<string, number> {
    const counts: Record<string, number> = {};
    for (const incident of incidents) {
      const key = selector(incident);
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  private buildDailySeries(
    incidents: Incident[],
  ): Array<{ date: string; count: number }> {
    const countsByDate = this.countBy(incidents, (incident) =>
      incident.createdAt.slice(0, 10),
    );
    return Object.entries(countsByDate)
      .map(([date, count]) => ({ date, count }))
      .sort((a, b) => a.date.localeCompare(b.date));
  }
}
