import { Controller, Get, Param, UseGuards, Res } from '@nestjs/common';
import { ReportsService } from './reports.service';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { UserRole } from '../users/entities/user.entity';
import type { Response } from 'express';

@UseGuards(RolesGuard)
@Controller('reports')
export class ReportsController {
  constructor(private readonly reportsService: ReportsService) {}

  @Get('attendance/:classId')
  @Roles(UserRole.ADMIN)
  getAttendanceReport(@Param('classId') classId: string) {
    return this.reportsService.getAttendanceReportForClass(classId);
  }

  @Get('attendance/:classId/download')
  @Roles(UserRole.ADMIN)
  async downloadAttendanceReport(@Param('classId') classId: string, @Res() res: Response) {
    const buffer = await this.reportsService.generateAttendanceReportExcel(classId);
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', `attachment; filename=attendance-report-${classId}.xlsx`);
    res.send(buffer);
  }
}
