import { Controller, Post, Body, Param, UseGuards, Get } from '@nestjs/common';
import { RecordingsService } from './recordings.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('recordings')
export class RecordingsController {
  constructor(private readonly recordingsService: RecordingsService) {}

  @Post('start')
  start(@Body('classId') classId: string) {
    return this.recordingsService.startRecording(classId);
  }

  @Post(':id/stop')
  stop(@Param('id') id: string) {
    return this.recordingsService.stopRecording(id);
  }

  @Get('class/:classId')
  findForClass(@Param('classId') classId: string) {
    return this.recordingsService.findForClass(classId);
  }
}
