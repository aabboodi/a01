import { Injectable } from '@nestjs/common';
import { UsersService } from '../users/users.service';
import { FollowersService } from '../followers/followers.service';

@Injectable()
export class MessagingService {
  constructor(
    private readonly usersService: UsersService,
    private readonly followersService: FollowersService,
  ) {}

  async sendBulkMessage(message: string): Promise<{ success: boolean; message: string; recipients: number }> {
    // 1. Fetch all students and followers
    const students = await this.usersService.findAll('student');
    const followers = await this.followersService.findAll();

    // 2. Aggregate all phone numbers (assuming user entity has phone_number)
    // We need to add phone_number to the User entity for this to work.
    const studentNumbers = students.map(s => (s as any).phone_number).filter(Boolean);
    const followerNumbers = followers.map(f => f.phone_number).filter(Boolean);

    const allNumbers = [...new Set([...studentNumbers, ...followerNumbers])];

    // 3. **Mock Implementation:** Log the action instead of sending real messages
    console.log('--- MOCK WHATSAPP API CALL ---');
    console.log(`Sending message: "${message}"`);
    console.log(`To ${allNumbers.length} recipients:`);
    console.log(allNumbers.join(', '));
    console.log('-----------------------------');

    // This is where the actual WhatsApp API integration would go.
    // For now, we just simulate success.

    return {
      success: true,
      message: 'Message sent successfully to the mock service.',
      recipients: allNumbers.length,
    };
  }
}
