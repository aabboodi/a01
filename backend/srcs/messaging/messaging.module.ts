import { Module } from '@nestjs/common';
import { MessagingService } from './messaging.service';
import { MessagingController } from './messaging.controller';
import { UsersModule } from '../users/users.module';
import { FollowersModule } from '../followers/followers.module';

@Module({
  imports: [UsersModule, FollowersModule], // Import modules to use their services
  providers: [MessagingService],
  controllers: [MessagingController],
})
export class MessagingModule {}
