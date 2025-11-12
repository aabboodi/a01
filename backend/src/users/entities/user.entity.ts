import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';

// Define an enum for user roles for use in the code
export enum UserRole {
  ADMIN = 'admin',
  TEACHER = 'teacher',
  STUDENT = 'student',
}

@Entity('users') // Specifies the table name
export class User {
  @PrimaryGeneratedColumn('uuid')
  user_id: string;

  @Column({ type: 'varchar', length: 255, nullable: false })
  full_name: string;

  @Column({ type: 'varchar', length: 100, unique: true, nullable: false })
  login_code: string;

  @Column({
    type: 'varchar',
    nullable: false,
  })
  role: UserRole;

  @CreateDateColumn({
    type: 'datetime', // Changed from 'timestamptz' to 'datetime'
    default: () => 'CURRENT_TIMESTAMP',
  })
  created_at: Date;

  @UpdateDateColumn({
    type: 'datetime', // Changed from 'timestamptz' to 'datetime'
    default: () => 'CURRENT_TIMESTAMP',
  })
  updated_at: Date;
}
