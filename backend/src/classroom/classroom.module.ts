import { Module } from '@nestjs/common';
import { ClassroomGateway } from './classroom.gateway';
import { ChatModule } from '../chat/chat.module'; // Import ChatModule
import { UsersModule } from '../users/users.module';
import { ClassesModule } from '../classes/classes.module';

@Module({
  imports: [ChatModule, UsersModule, ClassesModule], // Add ChatModule to imports
  providers: [ClassroomGateway]
})
export class ClassroomModule {}
