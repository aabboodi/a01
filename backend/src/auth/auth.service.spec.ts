import { Test, TestingModule } from '@nestjs/testing';
import { AuthService } from './auth.service';
import { UsersService } from '../users/users.service';
import { JwtService } from '@nestjs/jwt';
import { UnauthorizedException } from '@nestjs/common';
import { User, UserRole } from '../users/entities/user.entity';

// Mock User object for testing
const mockUser: User = {
  user_id: 'a-uuid',
  full_name: 'Test User',
  login_code: '12345',
  role: UserRole.STUDENT,
  phone_number: '1234567890',
  created_at: new Date(),
};

describe('AuthService', () => {
  let service: AuthService;
  let usersService: UsersService;
  let jwtService: JwtService;

  beforeEach(async () => {
    // Create mock objects for the dependencies
    const mockUsersService = {
      findOneByLoginCode: jest.fn(),
    };
    const mockJwtService = {
      sign: jest.fn().mockReturnValue('mock.jwt.token'),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: UsersService, useValue: mockUsersService },
        { provide: JwtService, useValue: mockJwtService },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
    usersService = module.get<UsersService>(UsersService);
    jwtService = module.get<JwtService>(JwtService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('login', () => {
    it('should return an access token for a valid user', async () => {
      // Arrange
      const loginCode = '12345';
      (usersService.findOneByLoginCode as jest.Mock).mockResolvedValue(mockUser);

      // Act
      const result = await service.login(loginCode);

      // Assert
      expect(usersService.findOneByLoginCode).toHaveBeenCalledWith(loginCode);
      expect(jwtService.sign).toHaveBeenCalledWith({
        userId: mockUser.user_id,
        loginCode: mockUser.login_code,
        role: mockUser.role,
      });
      expect(result).toEqual({ access_token: 'mock.jwt.token' });
    });

    it('should throw UnauthorizedException for an invalid login code', async () => {
      // Arrange
      const loginCode = 'wrongcode';
      (usersService.findOneByLoginCode as jest.Mock).mockRejectedValue(new Error()); // Simulate user not found

      // Act & Assert
      await expect(service.login(loginCode)).rejects.toThrow(UnauthorizedException);
    });
  });
});
