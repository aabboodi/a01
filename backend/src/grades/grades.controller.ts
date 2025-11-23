import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { GradesService } from './grades.service';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { UserRole } from '../users/entities/user.entity';

@UseGuards(RolesGuard)
@Controller('grades')
export class GradesController {
  constructor(private readonly gradesService: GradesService) {}

  @Get('class/:classId')
  @Roles(UserRole.ADMIN) // Only admin can access this
  async getGradesForClass(@Param('classId') classId: string) {
    return this.gradesService.getGradesForClass(classId);
  }
}
