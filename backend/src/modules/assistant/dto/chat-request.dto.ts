import { Type } from 'class-transformer';
import {
  IsOptional,
  IsString,
  IsUUID,
  Length,
  ValidateNested,
} from 'class-validator';
import { CoordinateDto } from '../../../common/dto/coordinate.dto';

export class ChatRequestDto {
  @IsString()
  @Length(1, 1000)
  message!: string;

  @IsOptional()
  @IsUUID()
  tripId?: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => CoordinateDto)
  location?: CoordinateDto;
}
