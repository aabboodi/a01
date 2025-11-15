import { Controller, Post, Body, Param, UseGuards, Get, UseInterceptors, UploadedFile, Res } from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { RecordingsService } from './recordings.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { Response } from 'express';
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

  @Post(':id/upload')
  @UseInterceptors(FileInterceptor('file', {
    storage: diskStorage({
      destination: './uploads/recordings',
      filename: (req, file, cb) => {
        const randomName = Array(32).fill(null).map(() => (Math.round(Math.random() * 16)).toString(16)).join('');
        return cb(null, `${randomName}${file.originalname}`);
      },
    }),
  }))
  uploadFile(@Param('id') id: string, @UploadedFile() file: Express.Multer.File) {
    return this.recordingsService.addRecordingFile(id, file.path);
  }

  @Get(':id/download')
  async downloadFile(@Param('id') id: string, @Res() res: Response) {
    const filePath = await this.recordingsService.getRecordingFilePath(id);
    res.download(filePath);
  }

  @Get('class/:classId')
  findForClass(@Param('classId') classId: string) {
    return this.recordingsService.findForClass(classId);
  }
}
