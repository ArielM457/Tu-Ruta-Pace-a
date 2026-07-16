import { Type } from 'class-transformer';
import { ValidateNested } from 'class-validator';
import { CoordinateDto } from '../../../common/dto/coordinate.dto';

export class EmergencyRouteRequestDto {
  @ValidateNested()
  @Type(() => CoordinateDto)
  origin!: CoordinateDto;
}
