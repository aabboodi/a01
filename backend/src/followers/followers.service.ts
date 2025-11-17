import { Injectable, ConflictException, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Follower } from './entities/follower.entity';
import { CreateFollowerDto } from './dto/create-follower.dto';

@Injectable()
export class FollowersService {
  constructor(
    @InjectRepository(Follower)
    private readonly followerRepository: Repository<Follower>,
  ) {}

  async create(createFollowerDto: CreateFollowerDto): Promise<Follower> {
    const { phone_number } = createFollowerDto;

    const existingFollower = await this.followerRepository.findOne({ where: { phone_number } });
    if (existingFollower) {
      throw new ConflictException(`Follower with phone number '${phone_number}' already exists.`);
    }

    const newFollower = this.followerRepository.create(createFollowerDto);
    return this.followerRepository.save(newFollower);
  }

  async findAll(): Promise<Follower[]> {
    return this.followerRepository.find();
  }

  async remove(followerId: string): Promise<void> {
    const follower = await this.followerRepository.findOneBy({ follower_id: followerId });
    if (!follower) {
        throw new NotFoundException(`Follower with ID '${followerId}' not found.`);
    }
    await this.followerRepository.remove(follower);
  }
}
