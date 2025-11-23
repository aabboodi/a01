import { Test, TestingModule } from '@nestjs/testing';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ClassesService } from './classes.service';
import { Class } from './entities/class.entity';
import { Enrollment } from './entities/enrollment.entity';
import { UsersService } from '../users/users.service';
import { User, UserRole } from '../users/entities/user.entity';
import { CreateClassDto } from './dto/create-class.dto';
import { BadRequestException, NotFoundException } from '@nestjs/common';

// Mock data
const mockTeacher: User = { user_id: 'teacher-uuid', full_name: 'Teacher', login_code: 't1', role: UserRole.TEACHER, created_at: new Date(), phone_number: '' };
const mockStudent: User = { user_id: 'student-uuid', full_name: 'Student', login_code: 's1', role: UserRole.STUDENT, created_at: new Date(), phone_number: '' };
const mockClass: Class = { class_id: 'class-uuid', class_name: 'Math 101', teacher: mockTeacher, enrollments: [] };

describe('ClassesService', () => {
  let service: ClassesService;
  let classRepository: Repository<Class>;
  let enrollmentRepository: Repository<Enrollment>;
  let usersService: UsersService;

  const mockClassRepository = {
    create: jest.fn().mockResolvedValue(mockClass),
    save: jest.fn().mockResolvedValue(mockClass),
    findOneBy: jest.fn(),
    remove: jest.fn(),
  };

  const mockEnrollmentRepository = {
    create: jest.fn(),
    save: jest.fn(),
    findOne: jest.fn(),
    delete: jest.fn(),
  };

  const mockUsersService = {
    findOneById: jest.fn(),
  };

  beforeEach(async () => {
    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ClassesService,
        { provide: getRepositoryToken(Class), useValue: mockClassRepository },
        { provide: getRepositoryToken(Enrollment), useValue: mockEnrollmentRepository },
        { provide: UsersService, useValue: mockUsersService },
      ],
    }).compile();

    service = module.get<ClassesService>(ClassesService);
    classRepository = module.get<Repository<Class>>(getRepositoryToken(Class));
    enrollmentRepository = module.get<Repository<Enrollment>>(getRepositoryToken(Enrollment));
    usersService = module.get<UsersService>(UsersService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  describe('create', () => {
    it('should create a class successfully', async () => {
      const createClassDto: CreateClassDto = { class_name: 'Math 101', teacher_id: 'teacher-uuid' };
      (usersService.findOneById as jest.Mock).mockResolvedValue(mockTeacher);
      (classRepository.create as jest.Mock).mockReturnValue(mockClass);
      (classRepository.save as jest.Mock).mockResolvedValue(mockClass);

      const result = await service.create(createClassDto);

      expect(usersService.findOneById).toHaveBeenCalledWith('teacher-uuid');
      expect(classRepository.create).toHaveBeenCalledWith({ class_name: 'Math 101', teacher: mockTeacher });
      expect(classRepository.save).toHaveBeenCalledWith(mockClass);
      expect(result).toEqual(mockClass);
    });

    it('should throw BadRequestException if the user is not a teacher', async () => {
      const createClassDto: CreateClassDto = { class_name: 'Math 101', teacher_id: 'student-uuid' };
      (usersService.findOneById as jest.Mock).mockResolvedValue(mockStudent); // User is a student

      await expect(service.create(createClassDto)).rejects.toThrow(BadRequestException);
    });
  });

  describe('enrollStudents', () => {
    it('should enroll students successfully', async () => {
        mockClassRepository.findOneBy.mockResolvedValue(mockClass);
        (usersService.findOneById as jest.Mock).mockResolvedValue(mockStudent);
        mockEnrollmentRepository.findOne.mockResolvedValue(null); // Not already enrolled
        mockEnrollmentRepository.create.mockReturnValue({ class: mockClass, student: mockStudent });

        await service.enrollStudents('class-uuid', ['student-uuid']);

        expect(mockEnrollmentRepository.save).toHaveBeenCalled();
    });

    it('should throw BadRequestException if a user is not a student', async () => {
        mockClassRepository.findOneBy.mockResolvedValue(mockClass);
        (usersService.findOneById as jest.Mock).mockResolvedValue(mockTeacher); // User is a teacher

        await expect(service.enrollStudents('class-uuid', ['teacher-uuid'])).rejects.toThrow(BadRequestException);
    });
  });

    describe('removeClass', () => {
        it('should remove a class and its enrollments', async () => {
            mockClassRepository.findOneBy.mockResolvedValue(mockClass);

            await service.removeClass('class-uuid');

            expect(enrollmentRepository.delete).toHaveBeenCalledWith({ class: { class_id: 'class-uuid' } });
            expect(classRepository.remove).toHaveBeenCalledWith(mockClass);
        });

        it('should throw NotFoundException if class does not exist', async () => {
            mockClassRepository.findOneBy.mockResolvedValue(null);

            await expect(service.removeClass('wrong-uuid')).rejects.toThrow(NotFoundException);
        });
    });
});
