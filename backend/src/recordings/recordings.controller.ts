import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { RecordingsService } from './recordings.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('recordings')
export class RecordingsController {
  constructor(private readonly recordingsService: RecordingsService) {}

  @Get('class/:classId')
  @Roles('admin') // Only admin can access this
  async getRecordingsForClass(@Param('classId') classId: string) {
    return this.recordingsService.getRecordingsForClass(classId);
  }
}
