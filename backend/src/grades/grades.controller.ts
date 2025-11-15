import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { GradesService } from './grades.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('grades')
export class GradesController {
  constructor(private readonly gradesService: GradesService) {}

  @Get('class/:classId')
  @Roles('admin') // Only admin can access this
  async getGradesForClass(@Param('classId') classId: string) {
    return this.gradesService.getGradesForClass(classId);
  }
}
