import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  Unique,
} from 'typeorm';
import { User } from '../users/entities/user.entity';
import { Class } from '../classes/entities/class.entity';

@Entity('grades')
@Unique(['student', 'class']) // Ensure one grade entry per student per class
export class Grade {
  @PrimaryGeneratedColumn('uuid')
  grade_id: string;

  @ManyToOne(() => User, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'student_id' })
  student: User;

  @ManyToOne(() => Class, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'class_id' })
  class: Class;

  @Column({ type: 'float', default: 0 })
  interaction_grade: number; // Max 7

  @Column({ type: 'float', default: 0 })
  homework_grade: number; // Max 7

  @Column({ type: 'float', default: 0 })
  oral_exam_grade: number; // Max 60

  @Column({ type: 'float', default: 0 })
  written_exam_grade: number; // Max 7 (Typo in spec? Assuming this should be higher, but following spec)

  @Column({ type: 'float', default: 0 })
  final_grade: number;
}
