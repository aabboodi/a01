import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

export enum UserRole {
  ADMIN = 'admin',
  TEACHER = 'teacher',
  STUDENT = 'student',
}

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  user_id: string;

  @Column({ length: 100 })
  full_name: string;

  @Column({ unique: true, length: 20 })
  login_code: string;

  @Column({
    type: 'enum',
    enum: UserRole,
  })
  role: UserRole;

  @Column({ nullable: true, length: 20 })
  phone_number: string;

  @Column({ type: 'int', nullable: true })
  age: number;

  @Column({ length: 100, nullable: true })
  education_level: string;

  @Column({ length: 255, nullable: true })
  address: string;

  @Column({ length: 20, nullable: true })
  father_phone_number: string;

  @CreateDateColumn()
  created_at: Date;
}
