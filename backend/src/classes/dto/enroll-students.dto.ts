import { IsArray, IsUUID } from 'class-validator';

export class EnrollStudentsDto {
  @IsArray()
  @IsUUID('4', { each: true }) // Validates each element in the array is a UUID
  student_ids: string[];
}
