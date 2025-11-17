import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('followers')
export class Follower {
  @PrimaryGeneratedColumn('uuid')
  follower_id: string;

  @Column({ type: 'varchar', length: 255, nullable: false })
  full_name: string;

  @Column({ type: 'varchar', length: 20, unique: true, nullable: false })
  phone_number: string;
}
