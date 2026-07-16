import { Controller, Get, Query } from '@nestjs/common';
import { Roles } from '../../../common/decorators/roles.decorator';
import { UserRole } from '../../../common/types/domain';
import { Incident } from '../../incidents/services/incidents.service';
import {
  CongestionSummaryQueryDto,
  GovernmentIncidentsQueryDto,
} from '../dto/government-queries.dto';
import {
  CongestionSummary,
  GovernmentService,
} from '../services/government.service';

@Controller('government')
@Roles(UserRole.Government)
export class GovernmentController {
  constructor(private readonly governmentService: GovernmentService) {}

  @Get('congestion/summary')
  getCongestionSummary(
    @Query() query: CongestionSummaryQueryDto,
  ): Promise<CongestionSummary> {
    return this.governmentService.buildCongestionSummary(query);
  }

  @Get('incidents')
  listIncidents(
    @Query() query: GovernmentIncidentsQueryDto,
  ): Promise<Incident[]> {
    return this.governmentService.listIncidents(query);
  }
}
