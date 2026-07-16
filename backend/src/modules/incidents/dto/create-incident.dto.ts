import { Type } from 'class-transformer';
import {
  IsIn,
  IsOptional,
  IsString,
  IsUrl,
  Length,
  ValidateNested,
} from 'class-validator';
import { CoordinateDto } from '../../../common/dto/coordinate.dto';
import { IncidentKind } from '../../../common/types/domain';

export const CITIZEN_REPORTABLE_KINDS = [
  IncidentKind.Blockade,
  IncidentKind.Protest,
  IncidentKind.Roadwork,
];

export class CreateIncidentDto {
  @IsIn(CITIZEN_REPORTABLE_KINDS)
  kind!: IncidentKind;

  @ValidateNested()
  @Type(() => CoordinateDto)
  position!: CoordinateDto;

  @IsString()
  @Length(3, 280)
  description!: string;

  @IsOptional()
  @IsUrl()
  photoUrl?: string;
}
