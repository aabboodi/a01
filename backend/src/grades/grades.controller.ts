import { Controller, Get, Post, Body, Param, UseGuards, ValidationPipe } from '@nestjs/common';
import { GradesService } from './grades.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { UpsertGradeDto } from './dto/upsert-grade.dto';

@UseGuards(JwtAuthGuard)
@Controller('grades')
export class GradesController {
  constructor(private readonly gradesService: GradesService) {}

  @Get('class/:classId')
  getGradesForClass(@Param('classId') classId: string) {
    return this.gradesService.getGradesForClass(classId);
  }

  @Post()
  upsertGrade(@Body(new ValidationPipe()) upsertGradeDto: UpsertGradeDto) {
    return this.gradesService.upsertGrade(upsertGradeDto);
  }
}
