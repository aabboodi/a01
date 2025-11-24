import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { TypeOrmModule, getRepositoryToken } from '@nestjs/typeorm';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { Repository } from 'typeorm';
import { User, UserRole } from '../src/users/entities/user.entity';
import { Class } from '../src/classes/entities/class.entity';
import { Enrollment } from '../src/classes/entities/enrollment.entity';
import { AuthModule } from '../src/auth/auth.module';
import { UsersModule } from '../src/users/users.module';
import { ClassesModule } from '../src/classes/classes.module';
import { AppController } from '../src/app.controller';
import { AppService } from '../src/app.service';

describe('App (e2e)', () => {
  let app: INestApplication;
  let userRepository: Repository<User>;

  const testUser = {
    full_name: 'Test Teacher',
    phone_number: '1234567890',
    login_code: 'TEACH01',
    role: UserRole.TEACHER,
    age: 30,
    educational_level: 'Masters',
    target_level: 'Grade 10',
  };

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [
        ConfigModule.forRoot({
          isGlobal: true,
          envFilePath: '.env',
        }),
        TypeOrmModule.forRootAsync({
          imports: [ConfigModule],
          useFactory: (configService: ConfigService) => ({
            type: 'postgres',
            host: configService.get<string>('DB_HOST'),
            port: configService.get<number>('DB_PORT'),
            username: configService.get<string>('DB_USERNAME'),
            password: configService.get<string>('DB_PASSWORD'),
            database: `${configService.get<string>('DB_DATABASE')}_test`,
            entities: [User, Class, Enrollment],
            synchronize: true,
            dropSchema: true,
          }),
          inject: [ConfigService],
        }),
        AuthModule,
        UsersModule,
        ClassesModule,
      ],
      controllers: [AppController],
      providers: [AppService],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe());
    await app.init();

    userRepository = moduleFixture.get<Repository<User>>(getRepositoryToken(User));
    await userRepository.save(testUser);
  });

  afterEach(async () => {
    await app.close();
  });

  it('/ (GET) should return "Hello World!"', () => {
    return request(app.getHttpServer())
      .get('/')
      .expect(200)
      .expect('Hello World!');
  });

  describe('/auth/login (POST)', () => {
    it('should return an access token for valid credentials', () => {
      return request(app.getHttpServer())
        .post('/auth/login')
        .send({ login_code: 'TEACH01' })
        .expect(200)
        .expect(res => {
          expect(res.body).toHaveProperty('access_token');
        });
    });

    it('should return 401 for invalid credentials', () => {
      return request(app.getHttpServer())
        .post('/auth/login')
        .send({ login_code: 'WRONG' })
        .expect(401);
    });
  });
});
