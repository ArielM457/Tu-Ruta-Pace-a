import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';
import { ComplaintTransportKind } from '../../../common/types/domain';

export class CreateComplaintDto {
  @IsOptional()
  @IsString()
  @IsNotEmpty()
  @MaxLength(30)
  vehicleIdentifier?: string;

  @IsEnum(ComplaintTransportKind)
  transportKind!: ComplaintTransportKind;

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
}
