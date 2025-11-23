import { Module } from '@nestjs/common';
import { ClassroomGateway } from './classroom.gateway';
import { ChatModule } from '../chat/chat.module'; // Import ChatModule
import { UsersModule } from '../users/users.module';
import { ClassesModule } from '../classes/classes.module';
import { AttendanceModule } from '../attendance/attendance.module';

@Module({
  imports: [ChatModule, UsersModule, ClassesModule, AttendanceModule], // Add ChatModule to imports
  providers: [ClassroomGateway]
})
export class ClassroomModule {}
