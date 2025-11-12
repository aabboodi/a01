import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest'; // Corrected import statement
import { TypeOrmModule } from '@nestjs/typeorm';
import { AppController } from '../src/app.controller';
import { AppService } from '../src/app.service';
import { UsersModule } from '../src/users/users.module';
import { User } from '../src/users/entities/user.entity';

describe('AppController (e2e)', () => {
  let app: INestApplication;

  beforeEach(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [
        // Set up the TypeORM connection for an in-memory SQLite database
        TypeOrmModule.forRoot({
          type: 'sqlite',
          database: ':memory:',
          entities: [User], // Directly reference the entity
          synchronize: true,
        }),
        // Import the module that will be tested
        UsersModule,
      ],
      controllers: [AppController],
      providers: [AppService],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
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
});
