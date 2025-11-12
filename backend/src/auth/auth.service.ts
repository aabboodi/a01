import { Injectable, UnauthorizedException } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { User } from '../users/entities/user.entity';

@Injectable()
export class AuthService {
  constructor(private readonly usersService: UsersService) {}

  /**
   * Validates a user based on their login code.
   * @param loginCode - The login code provided by the user.
   * @returns The full user object if the login is successful.
   * @throws UnauthorizedException if the login code is invalid.
   */
  async login(loginCode: string): Promise<User> {
    try {
      const user = await this.usersService.findOneByLoginCode(loginCode);
      return user;
    } catch (error) {
      // Catch the NotFoundException from UsersService and throw a more appropriate
      // UnauthorizedException for a failed login attempt.
      throw new UnauthorizedException('Invalid login code.');
    }
  }
}
