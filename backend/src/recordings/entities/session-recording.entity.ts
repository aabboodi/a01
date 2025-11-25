import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Class } from '../../classes/entities/class.entity';

@Entity('session_recordings')
export class SessionRecording {
  @PrimaryGeneratedColumn('uuid')
  recording_id: string;

  @ManyToOne(() => Class, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'class_id' })
  class: Class;

  @CreateDateColumn({ type: 'datetime', default: () => 'CURRENT_TIMESTAMP' })
  start_time: Date;

  @Column({ type: 'datetime', nullable: true })
  end_time: Date | null;

  @Column({ type: 'varchar', length: 255, nullable: true })
  file_path: string | null;
}
