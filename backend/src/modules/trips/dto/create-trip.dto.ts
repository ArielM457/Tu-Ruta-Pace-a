import { IsObject } from 'class-validator';

export class CreateTripDto {
  @IsObject()
  routeSnapshot!: Record<string, unknown>;
}
