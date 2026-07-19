import { HttpStatus, Injectable } from '@nestjs/common';
import { DomainException } from '../../../common/exceptions/domain.exception';
import {
  AccessibilityProfile,
  TravelPriority,
  UserRole,
} from '../../../common/types/domain';
import { BootstrapProfileDto } from '../dto/bootstrap-profile.dto';
import { UpdateProfileDto } from '../dto/update-profile.dto';
import {
  ProfileChanges,
  ProfileRecord,
  ProfilesRepository,
} from '../repositories/profiles.repository';

export interface ProfileResponse {
  id: string;
  displayName: string | null;
  phone: string | null;
  role: UserRole;
  accessibilityProfile: AccessibilityProfile;
  defaultPriority: TravelPriority;
  ayniPoints: number;
  routeAlertsEnabled: boolean;
  shareLocationWithFamily: boolean;
  createdAt: string;
}

@Injectable()
export class UsersService {
  constructor(private readonly profilesRepository: ProfilesRepository) {}

  async bootstrapProfile(
    userId: string,
    dto: BootstrapProfileDto,
  ): Promise<ProfileResponse> {
    const profile = await this.profilesRepository.createIfMissing(
      userId,
      dto.displayName ?? null,
    );
    return this.toResponse(profile);
  }

  async getProfile(userId: string): Promise<ProfileResponse> {
    const profile = await this.profilesRepository.findById(userId);
    if (!profile) {
      throw new DomainException(
        'PROFILE_NOT_FOUND',
        'Tu perfil aún no existe, vuelve a iniciar sesión',
        HttpStatus.NOT_FOUND,
      );
    }
    return this.toResponse(profile);
  }

  async updateProfile(
    userId: string,
    dto: UpdateProfileDto,
  ): Promise<ProfileResponse> {
    await this.getProfile(userId);
    const changes = this.toChanges(dto);
    const profile = await this.profilesRepository.update(userId, changes);
    return this.toResponse(profile);
  }

  private toChanges(dto: UpdateProfileDto): ProfileChanges {
    const changes: ProfileChanges = {};
    if (dto.displayName !== undefined) {
      changes.display_name = dto.displayName;
    }
    if (dto.phone !== undefined) {
      changes.phone = dto.phone;
    }
    if (dto.accessibilityProfile !== undefined) {
      changes.accessibility_profile = dto.accessibilityProfile;
    }
    if (dto.defaultPriority !== undefined) {
      changes.default_priority = dto.defaultPriority;
    }
    if (dto.routeAlertsEnabled !== undefined) {
      changes.route_alerts_enabled = dto.routeAlertsEnabled;
    }
    if (dto.shareLocationWithFamily !== undefined) {
      changes.share_location_with_family = dto.shareLocationWithFamily;
    }
    return changes;
  }

  private toResponse(profile: ProfileRecord): ProfileResponse {
    return {
      id: profile.id,
      displayName: profile.display_name,
      phone: profile.phone,
      role:
        (profile.role as UserRole) === UserRole.Government
          ? UserRole.Government
          : UserRole.Citizen,
      accessibilityProfile:
        profile.accessibility_profile as AccessibilityProfile,
      defaultPriority: profile.default_priority as TravelPriority,
      ayniPoints: profile.ayni_points,
      routeAlertsEnabled: profile.route_alerts_enabled,
      shareLocationWithFamily: profile.share_location_with_family,
      createdAt: profile.created_at,
    };
  }
}
