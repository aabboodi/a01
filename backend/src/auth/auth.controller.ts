import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { User } from '../users/entities/user.entity';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  /**
   * Endpoint for user login.
   * POST /auth/login
   */
  @Post('login')
  @HttpCode(HttpStatus.OK) // Return 200 OK on success instead of the default 201 Created
  login(@Body() loginDto: LoginDto): Promise<User> {
    return this.authService.login(loginDto.login_code);
  }
}
