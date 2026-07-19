import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUrl,
  IsUUID,
  MaxLength,
} from 'class-validator';
import {
  ComplaintTransportKind,
  ComplaintType,
} from '../../../common/types/domain';

export class CreateComplaintDto {
  @IsEnum(ComplaintType)
  type!: ComplaintType;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(30)
  vehicleIdentifier?: string;

  @IsOptional()
  @IsEnum(ComplaintTransportKind)
  transportKind?: ComplaintTransportKind;

  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(60)
  routeLabel?: string;

  @IsOptional()
  @IsUUID()
  lineId?: string;

  @IsOptional()
  @IsUUID()
  stopId?: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(1000)
  complaint!: string;

  @IsOptional()
  @IsUrl()
  photoUrl?: string;
}
