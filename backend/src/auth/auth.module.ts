import { Module } from '@nestjs/common';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { UsersModule } from '../users/users.module'; // Import UsersModule

@Module({
  imports: [UsersModule], // Add UsersModule to the imports
  controllers: [AuthController],
  providers: [AuthService],
})
export class AuthModule {}
