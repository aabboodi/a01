import { Controller, Get, Post, Body, Query, Delete, Param, ParseUUIDPipe, HttpCode, HttpStatus } from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { User } from './entities/user.entity';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post()
  create(@Body() createUserDto: CreateUserDto): Promise<User> {
    return this.usersService.create(createUserDto);
  }

  @Get()
  findAll(@Query('role') role?: string): Promise<User[]> {
    return this.usersService.findAll(role);
  }

  @Get('by-code/:code')
  findOneByLoginCode(@Param('code') code: string): Promise<User> {
    return this.usersService.findOneByLoginCode(code);
  }

  @Delete(':id')
  @HttpCode(HttpStatus.NO_CONTENT) // Return 204 No Content on successful deletion
  remove(@Param('id', ParseUUIDPipe) id: string): Promise<void> {
    return this.usersService.remove(id);
  }
}
