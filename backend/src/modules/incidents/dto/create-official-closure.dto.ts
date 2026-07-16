import { Type } from 'class-transformer';
import {
  IsISO8601,
  IsOptional,
  IsString,
  Length,
  ValidateNested,
} from 'class-validator';
import { CoordinateDto } from '../../../common/dto/coordinate.dto';

export class CreateOfficialClosureDto {
  @ValidateNested()
  @Type(() => CoordinateDto)
  position!: CoordinateDto;

  @IsString()
  @Length(3, 280)
  description!: string;

  @IsOptional()
  @IsISO8601()
  startsAt?: string;

  @IsOptional()
  @IsISO8601()
  expiresAt?: string;
}
