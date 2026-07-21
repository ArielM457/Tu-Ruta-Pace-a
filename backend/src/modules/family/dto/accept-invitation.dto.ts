import { IsNotEmpty, IsString, MaxLength, MinLength } from 'class-validator';

export class AcceptInvitationDto {
  @IsString()
  @IsNotEmpty()
  @MinLength(6)
  @MaxLength(10)
  code!: string;
}
