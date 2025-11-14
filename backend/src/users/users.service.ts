import { Injectable, ConflictException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { CreateUserDto } from './dto/create-user.dto';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  async create(createUserDto: CreateUserDto): Promise<User> {
    const { login_code } = createUserDto;

    const existingUser = await this.userRepository.findOne({ where: { login_code } });
    if (existingUser) {
      throw new ConflictException(`User with login code '${login_code}' already exists.`);
    }

    const newUser = this.userRepository.create(createUserDto);
    return this.userRepository.save(newUser);
  }

  async findAll(role?: string): Promise<User[]> {
    if (role) {
      return this.userRepository.find({ where: { role } });
    }
    return this.userRepository.find();
  }

  async findOneByLoginCode(loginCode: string): Promise<User> {
    const user = await this.userRepository.findOne({ where: { login_code: loginCode } });
    if (!user) {
      throw new NotFoundException(`User with login code '${loginCode}' not found.`);
    }
    return user;
  }

  /**
   * Finds a single user by their ID.
   * @param userId - The UUID of the user to search for.
   * @returns The user entity if found.
   * @throws NotFoundException if no user is found with the given ID.
   */
  async findOneById(userId: string): Promise<User> {
    const user = await this.userRepository.findOneBy({ user_id: userId });
    if (!user) {
      throw new NotFoundException(`User with ID '${userId}' not found.`);
    }
    return user;
  }

  async remove(userId: string): Promise<void> {
    const user = await this.findOneById(userId); // Reuse findOneById to handle not found error
    await this.userRepository.remove(user);
  }
}
