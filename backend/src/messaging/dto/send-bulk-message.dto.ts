import { IsNotEmpty, IsString, MinLength } from 'class-validator';

export class SendBulkMessageDto {
  @IsNotEmpty()
  @IsString()
  @MinLength(1)
  message: string;
}
