import { Type } from 'class-transformer';
import { IsOptional, IsString, Length, ValidateNested } from 'class-validator';
import { CoordinateDto } from '../../../common/dto/coordinate.dto';

export class VoiceRouteRequestDto {
  @IsString()
  @Length(1, 500)
  transcript!: string;

  @IsOptional()
  @ValidateNested()
  @Type(() => CoordinateDto)
  location?: CoordinateDto;
}
