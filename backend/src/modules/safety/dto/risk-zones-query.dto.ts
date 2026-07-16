import { IsISO8601, IsOptional } from 'class-validator';

export class RiskZonesQueryDto {
  @IsOptional()
  @IsISO8601()
  activeAt?: string;
}
