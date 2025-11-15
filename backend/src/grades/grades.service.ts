import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Grade } from './entities/grade.entity';
import { UpsertGradeDto } from './dto/upsert-grade.dto';
import { UsersService } from '../users/users.service';
import { ClassesService } from '../classes/classes.service';

@Injectable()
export class GradesService {
  constructor(
    @InjectRepository(Grade)
    private readonly gradeRepository: Repository<Grade>,
    private readonly usersService: UsersService,
    private readonly classesService: ClassesService,
  ) {}

  async getGradesForClass(classId: string): Promise<Grade[]> {
    return this.gradeRepository.find({
      where: { class: { class_id: classId } },
      relations: ['student'],
    });
  }

  async upsertGrade(upsertGradeDto: UpsertGradeDto): Promise<Grade> {
    const { studentId, classId, ...grades } = upsertGradeDto;

    const student = await this.usersService.findOneById(studentId);
    const classEntity = await this.classesService.findOne(classId);

    let grade = await this.gradeRepository.findOne({
      where: { student: { user_id: studentId }, class: { class_id: classId } },
    });

    if (!grade) {
      grade = this.gradeRepository.create({ student, class: classEntity });
    }

    Object.assign(grade, grades);

    // Calculate final grade
    grade.final_grade =
      grade.interaction_grade +
      grade.homework_grade +
      grade.oral_exam_grade +
      grade.written_exam_grade;

    return this.gradeRepository.save(grade);
  }
}
