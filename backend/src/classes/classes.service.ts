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

  async findOne(classId: string): Promise<Class> {
    const classEntity = await this.classRepository.findOne({
      where: { class_id: classId },
      relations: ['teacher'],
    });
    if (!classEntity) {
      throw new NotFoundException(`Class with ID ${classId} not found.`);
    }
    return classEntity;
  }

  async enrollStudents(classId: string, studentIds: string[]): Promise<void> {
    const classEntity = await this.classRepository.findOneBy({ class_id: classId });
    if (!classEntity) {
      throw new NotFoundException(`Class with ID ${classId} not found.`);
    }

    // Fetch all current enrollments for the class
    const currentEnrollments = await this.enrollmentRepository.find({
      where: { class: { class_id: classId } },
      relations: ['student'],
    });
    const currentStudentIds = currentEnrollments.map(e => e.student.user_id);

    // Students to add: in the new list but not in the current list
    const studentsToAdd = studentIds.filter(id => !currentStudentIds.includes(id));

    // Enrollments to remove: in the current list but not in the new list
    const enrollmentsToRemove = currentEnrollments.filter(e => !studentIds.includes(e.student.user_id));

    // Perform additions
    for (const studentId of studentsToAdd) {
      const student = await this.usersService.findOneById(studentId);
      if (student.role !== UserRole.STUDENT) {
        // Optionally, you can decide to throw an error or just skip.
        // For robustness, we'll skip non-student users.
        continue;
      }
      const enrollment = this.enrollmentRepository.create({ class: classEntity, student });
      await this.enrollmentRepository.save(enrollment);
    }

    // Perform removals
    if (enrollmentsToRemove.length > 0) {
      await this.enrollmentRepository.remove(enrollmentsToRemove);
    }
  }

  async findStudentsByClass(classId: string): Promise<any[]> {
    const enrollments = await this.enrollmentRepository.find({
      where: { class: { class_id: classId } },
      relations: ['student'],
    });
    return enrollments.map(e => e.student);
  }

  async findClassesByStudent(studentId: string): Promise<Class[]> {
    const enrollments = await this.enrollmentRepository.find({
      where: { student: { user_id: studentId } },
      relations: ['class', 'class.teacher'], // Eagerly load the class and its teacher
    });
    return enrollments.map(e => e.class);
  }

  async removeClass(classId: string): Promise<void> {
    const classEntity = await this.classRepository.findOneBy({ class_id: classId });
    if (!classEntity) {
      throw new NotFoundException(`Class with ID ${classId} not found.`);
    }

    // First, remove all enrollments associated with this class
    await this.enrollmentRepository.delete({ class: { class_id: classId } });

    // Then, remove the class itself
    await this.classRepository.remove(classEntity);
  }
}
