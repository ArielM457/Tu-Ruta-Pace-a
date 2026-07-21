import { HttpStatus, Injectable } from '@nestjs/common';
import { randomInt } from 'crypto';
import { DomainException } from '../../../common/exceptions/domain.exception';
import { TripStatus } from '../../../common/types/domain';
import { TripsService } from '../../trips/services/trips.service';
import { UsersService } from '../../users/services/users.service';
import { AcceptInvitationDto } from '../dto/accept-invitation.dto';
import { CreateFamilyGroupDto } from '../dto/create-family-group.dto';
import { InviteFamilyMemberDto } from '../dto/invite-family-member.dto';
import {
  FamilyMemberRecord,
  FamilyRepository,
} from '../repositories/family.repository';

export type FamilyMemberStatus = 'on_trip' | 'inactive' | 'hidden' | 'pending';

export interface FamilyMember {
  id: string;
  userId: string | null;
  displayName: string | null;
  relationshipLabel: string | null;
  status: FamilyMemberStatus;
  currentLineName: string | null;
  lastPingAt: string | null;
  inviteCode: string | null;
}

export interface FamilyGroupResponse {
  id: string;
  name: string;
  members: FamilyMember[];
}

export interface FamilyInvite {
  id: string;
  code: string;
  invitedEmail: string | null;
  relationshipLabel: string | null;
}

const INVITE_CODE_LENGTH = 6;
const INVITE_CODE_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

@Injectable()
export class FamilyService {
  constructor(
    private readonly familyRepository: FamilyRepository,
    private readonly usersService: UsersService,
    private readonly tripsService: TripsService,
  ) {}

  async createGroup(
    userId: string,
    dto: CreateFamilyGroupDto,
  ): Promise<FamilyGroupResponse> {
    const existing = await this.familyRepository.findActiveMembershipForUser(
      userId,
    );
    if (existing) {
      throw new DomainException(
        'ALREADY_IN_FAMILY_GROUP',
        'Ya perteneces a una cuenta familiar',
        HttpStatus.CONFLICT,
      );
    }
    const group = await this.familyRepository.createGroup(userId, dto.name);
    await this.familyRepository.createMember({
      group_id: group.id,
      user_id: userId,
      relationship_label: 'Yo',
      invited_email: null,
      invite_code: this.generateInviteCode(),
      status: 'active',
    });
    return this.buildGroupResponse(group.id, group.name);
  }

  async getMyGroup(userId: string): Promise<FamilyGroupResponse | null> {
    const membership = await this.familyRepository.findActiveMembershipForUser(
      userId,
    );
    if (!membership) {
      return null;
    }
    const group = await this.familyRepository.findGroupById(
      membership.group_id,
    );
    if (!group) {
      return null;
    }
    return this.buildGroupResponse(group.id, group.name);
  }

  async inviteMember(
    userId: string,
    dto: InviteFamilyMemberDto,
  ): Promise<FamilyInvite> {
    const membership = await this.familyRepository.findActiveMembershipForUser(
      userId,
    );
    if (!membership) {
      throw new DomainException(
        'FAMILY_GROUP_NOT_FOUND',
        'Primero crea tu cuenta familiar',
        HttpStatus.NOT_FOUND,
      );
    }
    const record = await this.familyRepository.createMember({
      group_id: membership.group_id,
      user_id: null,
      relationship_label: dto.relationshipLabel ?? null,
      invited_email: dto.email ?? null,
      invite_code: this.generateInviteCode(),
      status: 'pending',
    });
    return {
      id: record.id,
      code: record.invite_code,
      invitedEmail: record.invited_email,
      relationshipLabel: record.relationship_label,
    };
  }

  async acceptInvitation(
    userId: string,
    dto: AcceptInvitationDto,
  ): Promise<FamilyGroupResponse> {
    const existing = await this.familyRepository.findActiveMembershipForUser(
      userId,
    );
    if (existing) {
      throw new DomainException(
        'ALREADY_IN_FAMILY_GROUP',
        'Ya perteneces a una cuenta familiar',
        HttpStatus.CONFLICT,
      );
    }
    const pending = await this.familyRepository.findPendingByCode(
      dto.code.toUpperCase(),
    );
    if (!pending) {
      throw new DomainException(
        'INVITE_CODE_NOT_FOUND',
        'El código de invitación no existe o ya fue usado',
        HttpStatus.NOT_FOUND,
      );
    }
    await this.familyRepository.acceptMember(pending.id, userId);
    const group = await this.familyRepository.findGroupById(pending.group_id);
    return this.buildGroupResponse(group!.id, group!.name);
  }

  private async buildGroupResponse(
    groupId: string,
    groupName: string,
  ): Promise<FamilyGroupResponse> {
    const records = await this.familyRepository.findMembersByGroup(groupId);
    const members = await Promise.all(
      records.map((record) => this.toFamilyMember(record)),
    );
    return { id: groupId, name: groupName, members };
  }

  private async toFamilyMember(
    record: FamilyMemberRecord,
  ): Promise<FamilyMember> {
    if (record.status === 'pending' || !record.user_id) {
      return {
        id: record.id,
        userId: null,
        displayName: record.invited_email,
        relationshipLabel: record.relationship_label,
        status: 'pending',
        currentLineName: null,
        lastPingAt: null,
        inviteCode: record.invite_code,
      };
    }

    const profile = await this.usersService.getProfile(record.user_id);
    if (!profile.shareLocationWithFamily) {
      return {
        id: record.id,
        userId: record.user_id,
        displayName: profile.displayName,
        relationshipLabel: record.relationship_label,
        status: 'hidden',
        currentLineName: null,
        lastPingAt: null,
        inviteCode: null,
      };
    }

    const activeTrip = await this.tripsService.findActiveTrip(record.user_id);
    if (activeTrip && activeTrip.status === TripStatus.Active) {
      return {
        id: record.id,
        userId: record.user_id,
        displayName: profile.displayName,
        relationshipLabel: record.relationship_label,
        status: 'on_trip',
        currentLineName: this.extractCurrentLineName(activeTrip.routeSnapshot),
        lastPingAt: null,
        inviteCode: null,
      };
    }

    const lastPingAt = await this.familyRepository.findLastPingAt(
      record.user_id,
    );
    return {
      id: record.id,
      userId: record.user_id,
      displayName: profile.displayName,
      relationshipLabel: record.relationship_label,
      status: 'inactive',
      currentLineName: null,
      lastPingAt,
      inviteCode: null,
    };
  }

  private extractCurrentLineName(
    routeSnapshot: Record<string, unknown>,
  ): string | null {
    const legs = routeSnapshot.legs;
    if (!Array.isArray(legs)) {
      return null;
    }
    for (const leg of legs) {
      const lineName = (leg as { lineName?: string }).lineName;
      if (typeof lineName === 'string' && lineName.length > 0) {
        return lineName;
      }
    }
    return null;
  }

  private generateInviteCode(): string {
    let code = '';
    for (let i = 0; i < INVITE_CODE_LENGTH; i += 1) {
      code += INVITE_CODE_ALPHABET[randomInt(INVITE_CODE_ALPHABET.length)];
    }
    return code;
  }
}
