import { Controller, Post, Param, UseGuards, UseInterceptors, UploadedFile, Body } from '@nestjs/common';
import { RecordingsService } from './recordings.service';
import { RolesGuard } from '../auth/roles.guard';
import { Roles } from '../auth/roles.decorator';
import { UserRole } from '../users/entities/user.entity';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';

@UseGuards(RolesGuard)
@Controller('recordings')
export class RecordingsController {
  constructor(private readonly recordingsService: RecordingsService) {}

  @Post('start')
  @Roles(UserRole.TEACHER)
  async startRecording(@Body('classId') classId: string) {
    return this.recordingsService.startRecording(classId);
  }

  @Post(':id/stop')
  @Roles(UserRole.TEACHER)
  async stopRecording(@Param('id') id: string) {
    return this.recordingsService.stopRecording(id);
  }

  @Post(':id/upload')
  @Roles(UserRole.TEACHER)
  @UseInterceptors(FileInterceptor('file', {
    storage: diskStorage({
      destination: './uploads/recordings',
      filename: (req, file, cb) => {
        const randomName = Array(32).fill(null).map(() => (Math.round(Math.random() * 16)).toString(16)).join('');
        return cb(null, `${randomName}${extname(file.originalname)}`);
      },
    }),
  }))
  async uploadRecording(@Param('id') id: string, @UploadedFile() file: Express.Multer.File) {
    return this.recordingsService.addRecordingFile(id, file.path);
  }
}
