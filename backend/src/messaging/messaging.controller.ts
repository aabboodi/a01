import { Controller, Post, Body } from '@nestjs/common';
import { MessagingService } from './messaging.service';
import { SendBulkMessageDto } from './dto/send-bulk-message.dto';

@Controller('messaging')
export class MessagingController {
  constructor(private readonly messagingService: MessagingService) {}

  @Post('send-bulk')
  sendBulkMessage(@Body() sendBulkMessageDto: SendBulkMessageDto) {
    return this.messagingService.sendBulkMessage(sendBulkMessageDto.message);
  }
}
