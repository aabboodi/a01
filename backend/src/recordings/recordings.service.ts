import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SessionRecording } from './entities/session-recording.entity';
import { ClassesService } from '../classes/classes.service';

@Injectable()
export class RecordingsService {
  constructor(
    @InjectRepository(SessionRecording)
    private readonly recordingRepository: Repository<SessionRecording>,
    private readonly classesService: ClassesService,
  ) {}

  async startRecording(classId: string): Promise<SessionRecording> {
    const classEntity = await this.classesService.findOne(classId);
    const newRecording = this.recordingRepository.create({
      class: classEntity,
    });
    return this.recordingRepository.save(newRecording);
  }

  async stopRecording(recordingId: string): Promise<SessionRecording> {
    const recording = await this.recordingRepository.findOneBy({ recording_id: recordingId });
    if (!recording) {
      throw new NotFoundException(`Recording with ID ${recordingId} not found.`);
    }
    recording.end_time = new Date();
    return this.recordingRepository.save(recording);
  }

  async findForClass(classId: string): Promise<SessionRecording[]> {
    return this.recordingRepository.find({
      where: { class: { class_id: classId } },
      order: { start_time: 'DESC' },
    });
  }
}
