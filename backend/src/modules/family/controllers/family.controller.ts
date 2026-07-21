import { Body, Controller, Get, Post } from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import type { AuthenticatedUser } from '../../../common/types/domain';
import { AcceptInvitationDto } from '../dto/accept-invitation.dto';
import { CreateFamilyGroupDto } from '../dto/create-family-group.dto';
import { InviteFamilyMemberDto } from '../dto/invite-family-member.dto';
import {
  FamilyGroupResponse,
  FamilyInvite,
  FamilyService,
} from '../services/family.service';

@Controller('family')
export class FamilyController {
  constructor(private readonly familyService: FamilyService) {}

  @Post('groups')
  createGroup(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateFamilyGroupDto,
  ): Promise<FamilyGroupResponse> {
    return this.familyService.createGroup(user.userId, dto);
  }

  @Get('groups/me')
  getMyGroup(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<FamilyGroupResponse | null> {
    return this.familyService.getMyGroup(user.userId);
  }

  @Post('invitations')
  inviteMember(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: InviteFamilyMemberDto,
  ): Promise<FamilyInvite> {
    return this.familyService.inviteMember(user.userId, dto);
  }

  @Post('invitations/accept')
  acceptInvitation(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: AcceptInvitationDto,
  ): Promise<FamilyGroupResponse> {
    return this.familyService.acceptInvitation(user.userId, dto);
  }
}
