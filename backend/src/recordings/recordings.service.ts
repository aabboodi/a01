import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SessionRecording } from './entities/session-recording.entity';
import { ClassesService } from '../classes/classes.service';
import { ChatService } from '../chat/chat.service';
import { UsersService } from '../users/users.service';

@Injectable()
export class RecordingsService {
  constructor(
    @InjectRepository(SessionRecording)
    private readonly recordingRepository: Repository<SessionRecording>,
    private readonly classesService: ClassesService,
    private readonly chatService: ChatService,
    private readonly usersService: UsersService,
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

  async addRecordingFile(recordingId: string, filePath: string): Promise<SessionRecording> {
    const recording = await this.recordingRepository.findOne({
      where: { recording_id: recordingId },
      relations: ['class'],
    });
    if (!recording) {
      throw new NotFoundException(`Recording with ID ${recordingId} not found.`);
    }
    recording.file_path = filePath;

    // Send a system message to the chat
    const adminUser = await this.usersService.findAdmin(); // Assuming a method to find a system/admin user
    const message = `A new recording is available for download: ${filePath}`;
    await this.chatService.createMessage(message, adminUser, recording.class);

    return this.recordingRepository.save(recording);
  }

  async getRecordingFilePath(recordingId: string): Promise<string> {
    const recording = await this.recordingRepository.findOneBy({ recording_id: recordingId });
    if (!recording || !recording.file_path) {
      throw new NotFoundException(`Recording file for ID ${recordingId} not found.`);
    }
    return recording.file_path;
  }
}
