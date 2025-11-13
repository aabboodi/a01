import { IsNotEmpty, IsString, IsUUID } from 'class-validator';

export class CreateClassDto {
  @IsNotEmpty()
  @IsString()
  class_name: string;

  @IsNotEmpty()
  @IsUUID()
  teacher_id: string;
}
