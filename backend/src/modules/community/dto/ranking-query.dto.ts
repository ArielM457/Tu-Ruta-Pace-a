import { IsIn, IsOptional } from 'class-validator';

export class RankingQueryDto {
  @IsOptional()
  @IsIn(['week'])
  period?: 'week';
}
