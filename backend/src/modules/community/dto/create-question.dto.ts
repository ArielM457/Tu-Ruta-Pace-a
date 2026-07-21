import {
  IsEnum,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
} from 'class-validator';
import { CommunityQuestionKind } from '../../../common/types/domain';

export class CreateQuestionDto {
  @IsUUID()
  lineId!: string;

  @IsEnum(CommunityQuestionKind)
  kind!: CommunityQuestionKind;

  @IsOptional()
  @IsString()
  @MaxLength(280)
  content?: string;
}
