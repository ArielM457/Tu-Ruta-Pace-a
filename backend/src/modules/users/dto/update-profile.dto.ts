import { IsEnum, IsOptional, IsString, Length } from 'class-validator';
import {
  AccessibilityProfile,
  TravelPriority,
} from '../../../common/types/domain';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  @Length(2, 60)
  displayName?: string;

  @IsOptional()
  @IsEnum(AccessibilityProfile)
  accessibilityProfile?: AccessibilityProfile;

  @IsOptional()
  @IsEnum(TravelPriority)
  defaultPriority?: TravelPriority;
}
