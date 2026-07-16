import { Type } from 'class-transformer';
import {
  IsLatitude,
  IsLongitude,
  IsNumber,
  IsOptional,
  IsString,
  Matches,
  Max,
  Min,
} from 'class-validator';

const BBOX_PATTERN =
  /^-?\d+(\.\d+)?,-?\d+(\.\d+)?,-?\d+(\.\d+)?,-?\d+(\.\d+)?$/;

export class ActiveIncidentsQueryDto {
  @IsOptional()
  @IsString()
  @Matches(BBOX_PATTERN, {
    message: 'bbox debe tener el formato minLng,minLat,maxLng,maxLat',
  })
  bbox?: string;
}

export class PendingNearQueryDto {
  @Type(() => Number)
  @IsLatitude()
  lat!: number;

  @Type(() => Number)
  @IsLongitude()
  lng!: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(50)
  @Max(5000)
  radius?: number;
}
