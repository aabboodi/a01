import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { FollowersService } from './followers.service';
import { FollowersController } from './followers.controller';
import { Follower } from './entities/follower.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Follower])],
  controllers: [FollowersController],
  providers: [FollowersService],
})
export class FollowersModule {}
