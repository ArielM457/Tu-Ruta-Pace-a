import { IsUUID } from 'class-validator';

export class VehicleQueryDto {
  @IsUUID()
  lineId!: string;

  @IsUUID()
  stopId!: string;
}
