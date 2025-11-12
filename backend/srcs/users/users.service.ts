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

  async findAll(): Promise<User[]> {
    return this.userRepository.find();
  }

  /**
   * Finds a single user by their login code.
   * @param loginCode - The login code to search for.
   * @returns The user entity if found.
   * @throws NotFoundException if no user is found with the given code.
   */
  async findOneByLoginCode(loginCode: string): Promise<User> {
    const user = await this.userRepository.findOne({ where: { login_code: loginCode } });
    if (!user) {
      throw new NotFoundException(`User with login code '${loginCode}' not found.`);
    }
    return user;
  }
}
