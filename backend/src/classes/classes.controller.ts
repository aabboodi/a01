import { Controller, Post, Body, Get, Param, ParseUUIDPipe, HttpCode, HttpStatus } from '@nestjs/common';
import { ClassesService } from './classes.service';
import { CreateClassDto } from './dto/create-class.dto';
import { EnrollStudentsDto } from './dto/enroll-students.dto';

@Controller('classes')
export class ClassesController {
  constructor(private readonly classesService: ClassesService) {}

  @Post()
  create(@Body() createClassDto: CreateClassDto) {
    return this.classesService.create(createClassDto);
  }

  @Get()
  findAll() {
    return this.classesService.findAll();
  }

  @Post(':id/enroll')
  @HttpCode(HttpStatus.NO_CONTENT) // Return 204 No Content on success
  enrollStudents(
    @Param('id', ParseUUIDPipe) id: string,
    @Body() enrollStudentsDto: EnrollStudentsDto,
  ) {
    return this.classesService.enrollStudents(id, enrollStudentsDto.student_ids);
  }

  @Get(':id/students')
  findStudentsByClass(@Param('id', ParseUUIDPipe) id: string) {
    return this.classesService.findStudentsByClass(id);
  }
}
