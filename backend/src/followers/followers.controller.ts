import { Controller, Get, Post, Body, Delete, Param, ParseUUIDPipe, HttpCode, HttpStatus } from '@nestjs/common';
import { FollowersService } from './followers.service';
import { CreateFollowerDto } from './dto/create-follower.dto';
import { Follower } from './entities/follower.entity';

@Controller('followers')
export class FollowersController {
  constructor(private readonly followersService: FollowersService) {}

  @Post()
  create(@Body() createFollowerDto: CreateFollowerDto): Promise<Follower> {
    return this.followersService.create(createFollowerDto);
  }

  @Get()
  findAll(): Promise<Follower[]> {
    return this.followersService.findAll();
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT)
  remove(@Param('id', ParseUUIDPipe) id: string): Promise<void> {
    return this.followersService.remove(id);
  }
}
