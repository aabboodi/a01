import { IsNotEmpty, IsString, IsPhoneNumber } from 'class-validator';

export class CreateFollowerDto {
  @IsNotEmpty()
  @IsString()
  full_name: string;

  @IsNotEmpty()
  @IsPhoneNumber(null) // Use null for region-agnostic phone number validation
  phone_number: string;
}
