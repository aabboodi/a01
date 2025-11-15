import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RecordingsService } from './recordings.service';
import { RecordingsController } from './recordings.controller';
import { SessionRecording } from './entities/session-recording.entity';
import { ClassesModule } from '../classes/classes.module';

@Module({
  imports: [TypeOrmModule.forFeature([SessionRecording]), ClassesModule],
  controllers: [RecordingsController],
  providers: [RecordingsService],
})
export class RecordingsModule {}
