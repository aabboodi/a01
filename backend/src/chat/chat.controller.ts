import { Controller, Get, Param, UseGuards } from '@nestjs/common';
import { ChatService } from './chat.service';
import { RolesGuard } from '../auth/roles.guard';

@UseGuards(RolesGuard)
@Controller('chat')
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Get(':classId')
  async getMessagesForClass(@Param('classId') classId: string) {
    return this.chatService.getMessagesForClass(classId);
  }
}
