import { IsOptional, IsString, Length } from 'class-validator';

export class BootstrapProfileDto {
  @IsOptional()
  @IsString()
  @Length(2, 60)
  displayName?: string;
}
