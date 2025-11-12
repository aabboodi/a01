import { IsNotEmpty, IsString } from 'class-validator';

export class LoginDto {
  @IsNotEmpty({ message: 'Login code must not be empty.' })
  @IsString()
  login_code: string;
}
