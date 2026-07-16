import { IsEnum } from 'class-validator';
import { IncidentVote } from '../../../common/types/domain';

export class VoteIncidentDto {
  @IsEnum(IncidentVote)
  vote!: IncidentVote;
}
