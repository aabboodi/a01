import { IsNotEmpty, IsString, IsEnum, Length } from 'class-validator';
import { UserRole } from '../entities/user.entity';

export class CreateUserDto {
  @IsNotEmpty({ message: 'Full name must not be empty.' })
  @IsString()
  full_name: string;

  @IsNotEmpty({ message: 'Login code must not be empty.' })
  @IsString()
  @Length(4, 100, { message: 'Login code must be between 4 and 100 characters.' })
  login_code: string;

  @IsNotEmpty({ message: 'Role must not be empty.' })
  @IsEnum(UserRole, { message: 'Role must be one of the following: admin, teacher, student.' })
  role: UserRole;
}
