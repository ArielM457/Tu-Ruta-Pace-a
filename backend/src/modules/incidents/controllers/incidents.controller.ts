import {
  Body,
  Controller,
  Get,
  Param,
  ParseUUIDPipe,
  Post,
  Query,
} from '@nestjs/common';
import { CurrentUser } from '../../../common/decorators/current-user.decorator';
import { Roles } from '../../../common/decorators/roles.decorator';
import { UserRole } from '../../../common/types/domain';
import type { AuthenticatedUser } from '../../../common/types/domain';
import { CreateIncidentDto } from '../dto/create-incident.dto';
import { CreateOfficialClosureDto } from '../dto/create-official-closure.dto';
import {
  ActiveIncidentsQueryDto,
  PendingNearQueryDto,
} from '../dto/incidents-query.dto';
import { VoteIncidentDto } from '../dto/vote-incident.dto';
import { Incident, IncidentsService } from '../services/incidents.service';

@Controller('incidents')
export class IncidentsController {
  constructor(private readonly incidentsService: IncidentsService) {}

  @Post()
  report(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateIncidentDto,
  ): Promise<Incident> {
    return this.incidentsService.reportIncident(user.userId, dto);
  }

  @Post('official')
  @Roles(UserRole.Government)
  createOfficialClosure(
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: CreateOfficialClosureDto,
  ): Promise<Incident> {
    return this.incidentsService.createOfficialClosure(user.userId, dto);
  }

  @Post(':id/votes')
  vote(
    @Param('id', ParseUUIDPipe) incidentId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() dto: VoteIncidentDto,
  ): Promise<Incident> {
    return this.incidentsService.voteIncident(
      incidentId,
      user.userId,
      dto.vote,
    );
  }

  @Get('active')
  listActive(@Query() query: ActiveIncidentsQueryDto): Promise<Incident[]> {
    return this.incidentsService.getActiveIncidents(query.bbox);
  }

  @Get('pending/near')
  listPendingNear(@Query() query: PendingNearQueryDto): Promise<Incident[]> {
    return this.incidentsService.getPendingIncidentsNear(
      { lat: query.lat, lng: query.lng },
      query.radius,
    );
  }
}
