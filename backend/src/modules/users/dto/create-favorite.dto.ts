import { IsLatitude, IsLongitude, IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class CreateFavoriteDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(60)
  name!: string;

  @IsLatitude()
  lat!: number;

  @IsLongitude()
  lng!: number;
}
