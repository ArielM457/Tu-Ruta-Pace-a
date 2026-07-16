import { HttpStatus, Injectable } from '@nestjs/common';
import { DomainException } from '../../../common/exceptions/domain.exception';
import { IncidentStatus } from '../../../common/types/domain';
import { assertNoDatabaseError } from '../../../integrations/supabase/database-error';
import { SupabaseService } from '../../../integrations/supabase/supabase.service';

export interface IncidentRecord {
  id: string;
  reporter_id: string | null;
  kind: string;
  source: string;
  status: string;
  lat: number;
  lng: number;
  description: string;
  photo_url: string | null;
  confirmations: number;
  denials: number;
  starts_at: string;
  expires_at: string;
  created_at: string;
}

export interface NewIncidentRecord {
  reporter_id: string | null;
  kind: string;
  source: string;
  status: string;
  lat: number;
  lng: number;
  description: string;
  photo_url: string | null;
  starts_at: string;
  expires_at: string;
}

export interface IncidentSearchFilters {
  statuses?: string[];
  kind?: string;
  from?: string;
  to?: string;
}

@Injectable()
export class IncidentsRepository {
  constructor(private readonly supabaseService: SupabaseService) {}

  async create(record: NewIncidentRecord): Promise<IncidentRecord> {
    const { data, error } = await this.supabaseService.client
      .from('incidents')
      .insert(record)
      .select()
      .single();
    assertNoDatabaseError(error);
    return data as IncidentRecord;
  }

  async findById(incidentId: string): Promise<IncidentRecord | null> {
    const { data, error } = await this.supabaseService.client
      .from('incidents')
      .select('*')
      .eq('id', incidentId)
      .maybeSingle();
    assertNoDatabaseError(error);
    return data as IncidentRecord | null;
  }

  async findByStatuses(statuses: IncidentStatus[]): Promise<IncidentRecord[]> {
    const { data, error } = await this.supabaseService.client
      .from('incidents')
      .select('*')
      .in('status', statuses)
      .order('created_at', { ascending: false });
    assertNoDatabaseError(error);
    return (data ?? []) as IncidentRecord[];
  }

  async search(filters: IncidentSearchFilters): Promise<IncidentRecord[]> {
    let query = this.supabaseService.client.from('incidents').select('*');
    if (filters.statuses && filters.statuses.length > 0) {
      query = query.in('status', filters.statuses);
    }
    if (filters.kind) {
      query = query.eq('kind', filters.kind);
    }
    if (filters.from) {
      query = query.gte('created_at', filters.from);
    }
    if (filters.to) {
      query = query.lte('created_at', filters.to);
    }
    const { data, error } = await query.order('created_at', {
      ascending: false,
    });
    assertNoDatabaseError(error);
    return (data ?? []) as IncidentRecord[];
  }

  async registerVote(
    incidentId: string,
    userId: string,
    vote: string,
    confirmThreshold: number,
    resolveThreshold: number,
  ): Promise<IncidentRecord> {
    const { data, error } = await this.supabaseService.client.rpc(
      'register_incident_vote',
      {
        p_incident_id: incidentId,
        p_user_id: userId,
        p_vote: vote,
        p_confirm_threshold: confirmThreshold,
        p_resolve_threshold: resolveThreshold,
      },
    );
    if (error) {
      if (error.message.includes('ALREADY_VOTED')) {
        throw new DomainException(
          'ALREADY_VOTED',
          'Ya registraste tu confirmación para este incidente',
          HttpStatus.CONFLICT,
        );
      }
      if (error.message.includes('INCIDENT_NOT_FOUND')) {
        throw new DomainException(
          'INCIDENT_NOT_FOUND',
          'El incidente no existe',
          HttpStatus.NOT_FOUND,
        );
      }
      assertNoDatabaseError(error);
    }
    const rows = (data ?? []) as IncidentRecord[];
    if (rows.length === 0) {
      throw new DomainException(
        'INCIDENT_NOT_FOUND',
        'El incidente no existe',
        HttpStatus.NOT_FOUND,
      );
    }
    return rows[0];
  }

  async resolveExpired(now: string): Promise<void> {
    const { error } = await this.supabaseService.client
      .from('incidents')
      .update({ status: IncidentStatus.Resolved })
      .lt('expires_at', now)
      .in('status', [IncidentStatus.Pending, IncidentStatus.Active]);
    assertNoDatabaseError(error);
  }
}
