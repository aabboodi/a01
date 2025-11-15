import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ChatMessage } from './entities/chat-message.entity';
import { User } from '../users/entities/user.entity';
import { Class } from '../classes/entities/class.entity';

@Injectable()
export class ChatService {
  constructor(
    @InjectRepository(ChatMessage)
    private chatMessageRepository: Repository<ChatMessage>,
  ) {}

  async createMessage(
    message: string,
    user: User,
    classEntity: Class,
  ): Promise<ChatMessage> {
    const newMessage = this.chatMessageRepository.create({
      message,
      user,
      class: classEntity,
    });
    return this.chatMessageRepository.save(newMessage);
  }

  async getMessagesForClass(classId: string): Promise<ChatMessage[]> {
    return this.chatMessageRepository.find({
      where: { class: { class_id: classId } },
      relations: ['user'],
      order: { created_at: 'ASC' },
    });
  }
}
