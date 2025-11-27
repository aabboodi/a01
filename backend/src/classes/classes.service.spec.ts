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
    find: jest.fn(), // Add the missing find mock
    remove: jest.fn(), // Add remove for synchronization logic
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
    beforeEach(() => {
      // Reset mocks before each test in this describe block
      jest.clearAllMocks();
      mockClassRepository.findOneBy.mockResolvedValue(mockClass);
    });

    it('should add new students', async () => {
      const newStudent: User = { user_id: 'new-student-uuid', full_name: 'New Student', login_code: 's2', role: UserRole.STUDENT, created_at: new Date(), phone_number: '' };
      mockEnrollmentRepository.find.mockResolvedValue([]); // No current enrollments
      (usersService.findOneById as jest.Mock).mockResolvedValue(newStudent);
      mockEnrollmentRepository.create.mockReturnValue({ class: mockClass, student: newStudent });

      await service.enrollStudents('class-uuid', ['new-student-uuid']);

      expect(mockEnrollmentRepository.save).toHaveBeenCalledWith({ class: mockClass, student: newStudent });
      expect(mockEnrollmentRepository.remove).not.toHaveBeenCalled();
    });

    it('should remove students who are no longer in the list', async () => {
      const existingEnrollment = { class: mockClass, student: mockStudent };
      mockEnrollmentRepository.find.mockResolvedValue([existingEnrollment]); // Currently enrolled

      await service.enrollStudents('class-uuid', []); // Empty list means unenroll all

      expect(mockEnrollmentRepository.remove).toHaveBeenCalledWith([existingEnrollment]);
      expect(mockEnrollmentRepository.save).not.toHaveBeenCalled();
    });

    it('should synchronize enrollments (add and remove)', async () => {
      const studentToRemove: User = { user_id: 'student-to-remove-uuid', full_name: 'Remove Me', login_code: 's3', role: UserRole.STUDENT, created_at: new Date(), phone_number: '' };
      const studentToAdd: User = { user_id: 'student-to-add-uuid', full_name: 'Add Me', login_code: 's4', role: UserRole.STUDENT, created_at: new Date(), phone_number: '' };
      const enrollmentToRemove = { class: mockClass, student: studentToRemove };

      mockEnrollmentRepository.find.mockResolvedValue([enrollmentToRemove]); // One student is currently enrolled
      (usersService.findOneById as jest.Mock).mockResolvedValue(studentToAdd);
      mockEnrollmentRepository.create.mockReturnValue({ class: mockClass, student: studentToAdd });

      await service.enrollStudents('class-uuid', ['student-to-add-uuid']); // New list has one different student

      expect(mockEnrollmentRepository.save).toHaveBeenCalledWith({ class: mockClass, student: studentToAdd });
      expect(mockEnrollmentRepository.remove).toHaveBeenCalledWith([enrollmentToRemove]);
    });

    it('should not throw an error if a user to enroll is not a student', async () => {
      mockEnrollmentRepository.find.mockResolvedValue([]);
      (usersService.findOneById as jest.Mock).mockResolvedValue(mockTeacher); // Try to add a teacher

      // This should complete without throwing an error
      await service.enrollStudents('class-uuid', ['teacher-uuid']);

      expect(mockEnrollmentRepository.save).not.toHaveBeenCalled();
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
