import { Injectable, UnauthorizedException } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class AuthService {
  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
  ) {}

  /**
   * Validates a user and returns a JWT access token.
   * @param loginCode - The login code provided by the user.
   * @returns An object containing the JWT access token.
   * @throws UnauthorizedException if the login code is invalid.
   */
  async login(loginCode: string): Promise<{ access_token: string }> {
    try {
      const user = await this.usersService.findOneByLoginCode(loginCode);
      const payload = {
        userId: user.user_id,
        loginCode: user.login_code,
        role: user.role,
      };
      return {
        access_token: this.jwtService.sign(payload),
      };
    } catch (error) {
      throw new UnauthorizedException('Invalid login code.');
    }
  }
}
