import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AttendanceRecord, AttendanceStatus } from './entities/attendance-record.entity';
import { User } from '../users/entities/user.entity';
import { Class } from '../classes/entities/class.entity';

@Injectable()
export class AttendanceService {
  constructor(
    @InjectRepository(AttendanceRecord)
    private readonly attendanceRepository: Repository<AttendanceRecord>,
  ) {}

  async recordEvent(user: User, classEntity: Class, status: AttendanceStatus): Promise<AttendanceRecord> {
    const newRecord = this.attendanceRepository.create({
      user,
      class: classEntity,
      status,
    });
    return this.attendanceRepository.save(newRecord);
  }

  async getAttendanceForClass(classId: string): Promise<AttendanceRecord[]> {
    return this.attendanceRepository.find({
      where: { class: { class_id: classId } },
      relations: ['user'],
      order: { timestamp: 'ASC' },
    });
  }
}
