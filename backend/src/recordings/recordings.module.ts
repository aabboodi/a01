import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { RecordingsService } from './recordings.service';
import { RecordingsController } from './recordings.controller';
import { SessionRecording } from './entities/session-recording.entity';
import { ClassesModule } from '../classes/classes.module';
import { ChatModule } from '../chat/chat.module';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([SessionRecording]),
    ClassesModule,
    ChatModule,
    UsersModule,
  ],
  controllers: [RecordingsController],
  providers: [RecordingsService],
})
export class RecordingsModule {}
