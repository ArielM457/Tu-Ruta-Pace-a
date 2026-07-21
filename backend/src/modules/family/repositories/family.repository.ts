import { Injectable } from '@nestjs/common';
import { assertNoDatabaseError } from '../../../integrations/supabase/database-error';
import { SupabaseService } from '../../../integrations/supabase/supabase.service';

export interface FamilyGroupRecord {
  id: string;
  name: string;
  owner_id: string;
  created_at: string;
}

export interface FamilyMemberRecord {
  id: string;
  group_id: string;
  user_id: string | null;
  relationship_label: string | null;
  invited_email: string | null;
  invite_code: string;
  status: string;
  created_at: string;
}

export interface LastPingRow {
  user_id: string;
  recorded_at: string;
}

@Injectable()
export class FamilyRepository {
  constructor(private readonly supabaseService: SupabaseService) {}

  async createGroup(
    ownerId: string,
    name: string,
  ): Promise<FamilyGroupRecord> {
    const { data, error } = await this.supabaseService.client
      .from('family_groups')
      .insert({ owner_id: ownerId, name })
      .select()
      .single();
    assertNoDatabaseError(error);
    return data as FamilyGroupRecord;
  }

  async findGroupById(groupId: string): Promise<FamilyGroupRecord | null> {
    const { data, error } = await this.supabaseService.client
      .from('family_groups')
      .select('*')
      .eq('id', groupId)
      .maybeSingle();
    assertNoDatabaseError(error);
    return data as FamilyGroupRecord | null;
  }

  async findActiveMembershipForUser(
    userId: string,
  ): Promise<FamilyMemberRecord | null> {
    const { data, error } = await this.supabaseService.client
      .from('family_members')
      .select('*')
      .eq('user_id', userId)
      .eq('status', 'active')
      .maybeSingle();
    assertNoDatabaseError(error);
    return data as FamilyMemberRecord | null;
  }

  async createMember(record: {
    group_id: string;
    user_id: string | null;
    relationship_label: string | null;
    invited_email: string | null;
    invite_code: string;
    status: string;
  }): Promise<FamilyMemberRecord> {
    const { data, error } = await this.supabaseService.client
      .from('family_members')
      .insert(record)
      .select()
      .single();
    assertNoDatabaseError(error);
    return data as FamilyMemberRecord;
  }

  async findMembersByGroup(groupId: string): Promise<FamilyMemberRecord[]> {
    const { data, error } = await this.supabaseService.client
      .from('family_members')
      .select('*')
      .eq('group_id', groupId)
      .order('created_at', { ascending: true });
    assertNoDatabaseError(error);
    return (data ?? []) as FamilyMemberRecord[];
  }

  async findPendingByCode(code: string): Promise<FamilyMemberRecord | null> {
    const { data, error } = await this.supabaseService.client
      .from('family_members')
      .select('*')
      .eq('invite_code', code)
      .eq('status', 'pending')
      .maybeSingle();
    assertNoDatabaseError(error);
    return data as FamilyMemberRecord | null;
  }

  async acceptMember(
    memberId: string,
    userId: string,
  ): Promise<FamilyMemberRecord> {
    const { data, error } = await this.supabaseService.client
      .from('family_members')
      .update({ user_id: userId, status: 'active' })
      .eq('id', memberId)
      .select()
      .single();
    assertNoDatabaseError(error);
    return data as FamilyMemberRecord;
  }

  async findLastPingAt(userId: string): Promise<string | null> {
    const { data: shares, error: sharesError } = await this.supabaseService
      .client.from('location_shares').select('id').eq('user_id', userId);
    assertNoDatabaseError(sharesError);
    const shareIds = (shares ?? []).map((share) => (share as { id: string }).id);
    if (shareIds.length === 0) {
      return null;
    }
    const { data: pings, error: pingsError } = await this.supabaseService.client
      .from('location_pings')
      .select('recorded_at')
      .in('share_id', shareIds)
      .order('recorded_at', { ascending: false })
      .limit(1);
    assertNoDatabaseError(pingsError);
    const latest = (pings ?? [])[0] as { recorded_at: string } | undefined;
    return latest?.recorded_at ?? null;
  }
}
