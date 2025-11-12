import { Controller, Get, Post, Body } from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { User } from './entities/user.entity';

@Controller('users') // Defines the base route for this controller (e.g., /users)
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  /**
   * Endpoint to create a new user.
   * POST /users
   */
  @Post()
  create(@Body() createUserDto: CreateUserDto): Promise<User> {
    return this.usersService.create(createUserDto);
  }

  /**
   * Endpoint to retrieve all users.
   * GET /users
   */
  @Get()
  findAll(): Promise<User[]> {
    return this.usersService.findAll();
  }
}
