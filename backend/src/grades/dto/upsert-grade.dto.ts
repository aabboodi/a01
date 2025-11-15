import { IsNumber, IsString, Max, Min } from 'class-validator';

export class UpsertGradeDto {
  @IsString()
  studentId: string;

  @IsString()
  classId: string;

  @IsNumber()
  @Min(0)
  @Max(7)
  interaction_grade: number;

  @IsNumber()
  @Min(0)
  @Max(7)
  homework_grade: number;

  @IsNumber()
  @Min(0)
  @Max(60)
  oral_exam_grade: number;

  @IsNumber()
  @Min(0)
  @Max(7)
  written_exam_grade: number;
}
