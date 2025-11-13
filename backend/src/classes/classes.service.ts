import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, FindManyOptions } from 'typeorm';
import { Class } from './entities/class.entity';
import { Enrollment } from './entities/enrollment.entity';
import { CreateClassDto } from './dto/create-class.dto';
import { UsersService } from '../users/users.service';
import { UserRole } from '../users/entities/user.entity';

@Injectable()
export class ClassesService {
  constructor(
    @InjectRepository(Class)
    private readonly classRepository: Repository<Class>,
    @InjectRepository(Enrollment)
    private readonly enrollmentRepository: Repository<Enrollment>,
    private readonly usersService: UsersService,
  ) {}

  async create(createClassDto: CreateClassDto): Promise<Class> {
    const { class_name, teacher_id } = createClassDto;

    const teacher = await this.usersService.findOneById(teacher_id);
    if (teacher.role !== UserRole.TEACHER) {
      throw new BadRequestException('The assigned user is not a teacher.');
    }

    const newClass = this.classRepository.create({ class_name, teacher });
    return this.classRepository.save(newClass);
  }

  async findAll(teacherId?: string): Promise<Class[]> {
    const options: FindManyOptions<Class> = { relations: ['teacher'] };
    if (teacherId) {
      options.where = { teacher: { user_id: teacherId } };
    }
    return this.classRepository.find(options);
  }

  async enrollStudents(classId: string, studentIds: string[]): Promise<void> {
    const classEntity = await this.classRepository.findOneBy({ class_id: classId });
    if (!classEntity) {
      throw new NotFoundException(`Class with ID ${classId} not found.`);
    }

    for (const studentId of studentIds) {
      const student = await this.usersService.findOneById(studentId);
      if (student.role !== UserRole.STUDENT) {
        throw new BadRequestException(`User with ID ${studentId} is not a student.`);
      }

      const existingEnrollment = await this.enrollmentRepository.findOne({
        where: { class: { class_id: classId }, student: { user_id: studentId } },
      });

      if (!existingEnrollment) {
        const enrollment = this.enrollmentRepository.create({ class: classEntity, student });
        await this.enrollmentRepository.save(enrollment);
      }
    }
  }

  async findStudentsByClass(classId: string): Promise<any[]> {
    const enrollments = await this.enrollmentRepository.find({
      where: { class: { class_id: classId } },
      relations: ['student'],
    });
    return enrollments.map(e => e.student);
  }
}
