import { IsString, MinLength } from 'class-validator';

export class PlacesAutocompleteQueryDto {
  @IsString()
  @MinLength(2)
  q!: string;
}
