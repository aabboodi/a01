import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  OneToMany,
} from 'typeorm';
import { User } from '../users/entities/user.entity';
import { Enrollment } from './enrollment.entity';

@Entity('classes')
export class Class {
  @PrimaryGeneratedColumn('uuid')
  class_id: string;

  @Column({ type: 'varchar', length: 255, nullable: false })
  class_name: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'teacher_id' })
  teacher: User;

  @OneToMany(() => Enrollment, enrollment => enrollment.class)
  enrollments: Enrollment[];

  @CreateDateColumn({ type: 'datetime', default: () => 'CURRENT_TIMESTAMP' })
  created_at: Date;

  @UpdateDateColumn({ type: 'datetime', default: () => 'CURRENT_TIMESTAMP' })
  updated_at: Date;
}
