import { IsEnum, IsISO8601, IsOptional } from 'class-validator';
import { IncidentKind, IncidentStatus } from '../../../common/types/domain';

export class CongestionSummaryQueryDto {
  @IsOptional()
  @IsISO8601()
  from?: string;

  @IsOptional()
  @IsISO8601()
  to?: string;
}

export class GovernmentIncidentsQueryDto {
  @IsOptional()
  @IsEnum(IncidentStatus)
  status?: IncidentStatus;

  @IsOptional()
  @IsEnum(IncidentKind)
  kind?: IncidentKind;

  @IsOptional()
  @IsISO8601()
  from?: string;

  @IsOptional()
  @IsISO8601()
  to?: string;
}
