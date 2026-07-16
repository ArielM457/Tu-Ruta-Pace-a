import { Type } from 'class-transformer';
import { IsEnum, IsOptional, ValidateNested } from 'class-validator';
import { CoordinateDto } from '../../../common/dto/coordinate.dto';
import {
  AccessibilityProfile,
  TravelPriority,
} from '../../../common/types/domain';

export class RouteRecommendationRequestDto {
  @ValidateNested()
  @Type(() => CoordinateDto)
  origin!: CoordinateDto;

  @ValidateNested()
  @Type(() => CoordinateDto)
  destination!: CoordinateDto;

  @IsOptional()
  @IsEnum(TravelPriority)
  priority?: TravelPriority;

  @IsOptional()
  @IsEnum(AccessibilityProfile)
  accessibility?: AccessibilityProfile;
}
