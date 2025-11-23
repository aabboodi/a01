import { Module } from '@nestjs/common';
import { ClassroomGateway } from './classroom.gateway';
import { ChatModule } from '../chat/chat.module'; // Import ChatModule
import { UsersModule } from '../users/users.module';
import { ClassesModule } from '../classes/classes.module';
import { AttendanceModule } from '../attendance/attendance.module';
import { MediasoupModule } from '../mediasoup/mediasoup.module';
import { RedisModule } from '../redis/redis.module';

@Module({
  imports: [
    ChatModule,
    UsersModule,
    ClassesModule,
    AttendanceModule,
    MediasoupModule,
    RedisModule,
  ],
  providers: [ClassroomGateway],
})
export class ClassroomModule {}
