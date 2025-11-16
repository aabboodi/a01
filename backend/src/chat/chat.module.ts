import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ChatService } from './chat.service';
import { ChatController } from './chat.controller';
import { ChatMessage } from './entities/chat-message.entity';
import { UsersModule } from '../users/users.module';
import { ClassesModule } from '../classes/classes.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([ChatMessage]),
    UsersModule,
    ClassesModule,
  ],
  controllers: [ChatController],
  providers: [ChatService],
  exports: [ChatService], // Export ChatService to be used in other modules
})
export class ChatModule {}
