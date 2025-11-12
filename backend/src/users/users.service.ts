import { Injectable, ConflictException } from '@nestjs/common';
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

  /**
   * Creates a new user in the database.
   * @param createUserDto - The data for the new user.
   * @returns The newly created user entity.
   * @throws ConflictException if a user with the same login code already exists.
   */
  async create(createUserDto: CreateUserDto): Promise<User> {
    const { login_code } = createUserDto;

    // Check if a user with the same login code already exists
    const existingUser = await this.userRepository.findOne({ where: { login_code } });
    if (existingUser) {
      throw new ConflictException(`User with login code '${login_code}' already exists.`);
    }

    // Create a new user instance and save it
    const newUser = this.userRepository.create(createUserDto);
    return this.userRepository.save(newUser);
  }

  /**
   * Finds all users in the database.
   * @returns A list of all user entities.
   */
  async findAll(): Promise<User[]> {
    return this.userRepository.find();
  }
}
