import { IsArray, IsNotEmpty, IsUUID } from 'class-validator';

export class EnrollStudentsDto {
  @IsArray()
  @IsUUID('4', { each: true }) // Validates each element in the array is a UUID
  @IsNotEmpty()
  student_ids: string[];
}
