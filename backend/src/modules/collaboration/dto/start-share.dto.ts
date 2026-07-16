import { IsUUID } from 'class-validator';

export class StartShareDto {
  @IsUUID()
  tripId!: string;

  @IsUUID()
  lineId!: string;
}
