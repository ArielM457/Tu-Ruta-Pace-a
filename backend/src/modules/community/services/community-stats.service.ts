import { Injectable } from '@nestjs/common';
import { AyniPointsService } from '../../collaboration/services/ayni-points.service';
import {
  CommunityFeedRow,
  CommunityStatsRepository,
  WeeklyRankingRow,
} from '../repositories/community-stats.repository';

export enum CommunityBadge {
  Hero = 'hero',
  Active = 'active',
  Collaborator = 'collaborator',
  Member = 'member',
  New = 'new',
}

export interface RankingEntry {
  userId: string;
  displayName: string;
  points: number;
  rank: number;
  badge: CommunityBadge;
}

export interface RankingResponse {
  period: 'week';
  top: RankingEntry[];
  requester: RankingEntry;
}

export interface FeedEntry {
  id: string;
  displayName: string;
  reason: string;
  points: number;
  createdAt: string;
}

export interface PointsConfigResponse {
  reportReward: number;
  verifyReward: number;
  answerReward: number;
  askCost: number;
}

const RANKING_TOP_COUNT = 10;
const HERO_THRESHOLD = 800;
const ACTIVE_THRESHOLD = 500;
const COLLABORATOR_THRESHOLD = 400;
const MEMBER_THRESHOLD = 250;
const DEFAULT_FEED_LIMIT = 20;

@Injectable()
export class CommunityStatsService {
  constructor(
    private readonly repository: CommunityStatsRepository,
    private readonly ayniPointsService: AyniPointsService,
  ) {}

  getPointsConfig(): PointsConfigResponse {
    return {
      reportReward: this.ayniPointsService.verifiedReportReward,
      verifyReward: this.ayniPointsService.confirmedIncidentReward,
      answerReward: this.ayniPointsService.answerReward,
      askCost: this.ayniPointsService.questionCost,
    };
  }

  async getWeeklyRanking(userId: string): Promise<RankingResponse> {
    const rows = await this.repository.getWeeklyRanking();
    const top = rows
      .slice(0, RANKING_TOP_COUNT)
      .map((row) => this.toRankingEntry(row));
    const requesterRow = rows.find((row) => row.user_id === userId);
    const requester = requesterRow
      ? this.toRankingEntry(requesterRow)
      : {
          userId,
          displayName: 'Tú',
          points: 0,
          rank: rows.length + 1,
          badge: this.badgeFor(0),
        };
    return { period: 'week', top, requester };
  }

  async getFeed(limit: number = DEFAULT_FEED_LIMIT): Promise<FeedEntry[]> {
    const rows = await this.repository.getFeed(limit);
    return rows.map((row) => this.toFeedEntry(row));
  }

  private toRankingEntry(row: WeeklyRankingRow): RankingEntry {
    return {
      userId: row.user_id,
      displayName: row.display_name ?? 'Colaborador',
      points: Number(row.points),
      rank: Number(row.rnk),
      badge: this.badgeFor(Number(row.points)),
    };
  }

  private toFeedEntry(row: CommunityFeedRow): FeedEntry {
    return {
      id: row.id,
      displayName: row.display_name ?? 'Colaborador',
      reason: row.reason,
      points: row.amount,
      createdAt: row.created_at,
    };
  }

  private badgeFor(points: number): CommunityBadge {
    if (points >= HERO_THRESHOLD) return CommunityBadge.Hero;
    if (points >= ACTIVE_THRESHOLD) return CommunityBadge.Active;
    if (points >= COLLABORATOR_THRESHOLD) return CommunityBadge.Collaborator;
    if (points >= MEMBER_THRESHOLD) return CommunityBadge.Member;
    return CommunityBadge.New;
  }
}
