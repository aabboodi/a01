# Node.js Backend Architecture - المعهد الأول

## Technology Stack
- **Framework**: NestJS (Enterprise-grade Node.js framework)
- **Database**: PostgreSQL with TypeORM
- **Real-time**: Socket.io for WebRTC signaling
- **Authentication**: JWT with refresh tokens
- **Security**: Helmet, CORS, rate limiting
- **File Storage**: AWS S3 or local storage
- **Caching**: Redis for session management
- **Validation**: class-validator and class-transformer

## Project Structure
```
src/
├── main.ts
├── app.module.ts
├── common/
│   ├── decorators/
│   ├── filters/
│   ├── guards/
│   ├── interceptors/
│   ├── middleware/
│   └── pipes/
├── modules/
│   ├── auth/
│   │   ├── auth.controller.ts
│   │   ├── auth.service.ts
│   │   ├── auth.module.ts
│   │   ├── dto/
│   │   ├── entities/
│   │   └── strategies/
│   ├── users/
│   │   ├── users.controller.ts
│   │   ├── users.service.ts
│   │   ├── users.module.ts
│   │   ├── dto/
│   │   └── entities/
│   ├── classes/
│   ├── sessions/
│   ├── webrtc/
│   ├── chat/
│   ├── recordings/
│   └── admin/
├── database/
│   ├── database.module.ts
│   └── migrations/
├── services/
│   ├── socket.service.ts
│   ├── storage.service.ts
│   ├── notification.service.ts
│   └── sync.service.ts
└── config/
    ├── database.config.ts
    ├── jwt.config.ts
    └── app.config.ts
```

## Core Modules Implementation

### 1. Authentication Module

#### JWT Strategy
```typescript
@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor(
    private configService: ConfigService,
    private authService: AuthService,
  ) {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: configService.get<string>('JWT_SECRET'),
    });
  }

  async validate(payload: any) {
    return this.authService.validateUser(payload.sub);
  }
}
```

#### Auth Controller
```typescript
@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() loginDto: LoginDto) {
    return this.authService.login(loginDto);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  async refresh(@Body() refreshDto: RefreshTokenDto) {
    return this.authService.refreshTokens(refreshDto.refreshToken);
  }

  @Post('logout')
  @UseGuards(JwtAuthGuard)
  @HttpCode(HttpStatus.OK)
  async logout(@Request() req) {
    return this.authService.logout(req.user.id);
  }
}
```

### 2. WebRTC Signaling Module

#### WebRTC Gateway
```typescript
@WebSocketGateway({
  cors: {
    origin: process.env.FRONTEND_URL,
    credentials: true,
  },
})
export class WebRtcGateway implements OnGatewayConnection, OnGatewayDisconnect {
  constructor(
    private webRtcService: WebRtcService,
    private socketService: SocketService,
  ) {}

  @WebSocketServer()
  server: Server;

  handleConnection(client: Socket) {
    console.log(`Client connected: ${client.id}`);
    this.socketService.addClient(client);
  }

  handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
    this.socketService.removeClient(client);
    this.webRtcService.handleDisconnect(client);
  }

  @SubscribeMessage('join-session')
  async handleJoinSession(
    @MessageBody() data: JoinSessionDto,
    @ConnectedSocket() client: Socket,
  ) {
    const session = await this.webRtcService.joinSession(
      client,
      data.sessionId,
      data.userId,
    );
    
    client.join(`session-${data.sessionId}`);
    
    // Notify other participants
    client.to(`session-${data.sessionId}`).emit('user-joined', {
      userId: data.userId,
      socketId: client.id,
    });

    return { success: true, session };
  }

  @SubscribeMessage('offer')
  async handleOffer(
    @MessageBody() data: OfferDto,
    @ConnectedSocket() client: Socket,
  ) {
    client.to(data.targetSocketId).emit('offer', {
      offer: data.offer,
      senderSocketId: client.id,
    });
  }

  @SubscribeMessage('answer')
  async handleAnswer(
    @MessageBody() data: AnswerDto,
    @ConnectedSocket() client: Socket,
  ) {
    client.to(data.targetSocketId).emit('answer', {
      answer: data.answer,
      senderSocketId: client.id,
    });
  }

  @SubscribeMessage('ice-candidate')
  async handleIceCandidate(
    @MessageBody() data: IceCandidateDto,
    @ConnectedSocket() client: Socket,
  ) {
    client.to(data.targetSocketId).emit('ice-candidate', {
      candidate: data.candidate,
      senderSocketId: client.id,
    });
  }

  @SubscribeMessage('request-to-speak')
  async handleRequestToSpeak(
    @MessageBody() data: RequestToSpeakDto,
    @ConnectedSocket() client: Socket,
  ) {
    const sessionId = this.socketService.getSessionId(client);
    const teacherSocket = await this.socketService.getTeacherSocket(sessionId);
    
    client.to(teacherSocket).emit('student-request', {
      studentId: data.studentId,
      studentName: data.studentName,
    });
  }

  @SubscribeMessage('allow-speech')
  async handleAllowSpeech(
    @MessageBody() data: AllowSpeechDto,
    @ConnectedSocket() client: Socket,
  ) {
    client.to(data.studentSocketId).emit('speech-allowed', {
      allowed: true,
      grantedBy: data.teacherId,
    });
  }
}
```

#### WebRTC Service
```typescript
@Injectable()
export class WebRtcService {
  constructor(
    @InjectRepository(Session)
    private sessionRepository: Repository<Session>,
    @InjectRepository(SessionParticipant)
    private participantRepository: Repository<SessionParticipant>,
  ) {}

  async joinSession(
    client: Socket,
    sessionId: string,
    userId: string,
  ): Promise<Session> {
    const session = await this.sessionRepository.findOne({
      where: { id: sessionId },
      relations: ['participants'],
    });

    if (!session) {
      throw new NotFoundException('Session not found');
    }

    // Add participant to session
    const participant = this.participantRepository.create({
      sessionId,
      userId,
      socketId: client.id,
      joinedAt: new Date(),
      isActive: true,
    });

    await this.participantRepository.save(participant);

    // Update session participant count
    session.participantsCount = session.participants.length + 1;
    await this.sessionRepository.save(session);

    return session;
  }

  async handleDisconnect(client: Socket) {
    const participant = await this.participantRepository.findOne({
      where: { socketId: client.id },
    });

    if (participant) {
      participant.isActive = false;
      participant.leftAt = new Date();
      await this.participantRepository.save(participant);
    }
  }
}
```

### 3. Recording Module

#### Recording Service
```typescript
@Injectable()
export class RecordingService {
  constructor(
    private storageService: StorageService,
    @InjectRepository(Recording)
    private recordingRepository: Repository<Recording>,
  ) {}

  async processRecording(
    sessionId: string,
    file: Express.Multer.File,
    metadata: RecordingMetadataDto,
  ): Promise<Recording> {
    // Upload to cloud storage
    const fileUrl = await this.storageService.uploadFile(file, {
      folder: `recordings/${sessionId}`,
      public: false,
    });

    // Create recording record
    const recording = this.recordingRepository.create({
      sessionId,
      fileName: file.originalname,
      fileUrl,
      fileSize: file.size,
      duration: metadata.duration,
      quality: metadata.quality || '720p',
      processed: true,
    });

    return this.recordingRepository.save(recording);
  }

  async generateSessionReport(sessionId: string): Promise<SessionReport> {
    const session = await this.sessionRepository.findOne({
      where: { id: sessionId },
      relations: ['class', 'teacher', 'attendance', 'attendance.student'],
    });

    const report = {
      sessionId,
      className: session.class.name,
      teacherName: session.teacher.fullName,
      sessionDate: session.sessionDate,
      startTime: session.startTime,
      endTime: session.endTime,
      durationMinutes: session.durationMinutes,
      studentsPresent: session.attendance.filter(a => a.isPresent).length,
      studentsAbsent: session.attendance.filter(a => !a.isPresent).length,
      totalStudents: session.attendance.length,
      averageAttendanceDuration: this.calculateAverageDuration(session.attendance),
      recordingUrl: session.recording?.fileUrl,
      chatMessagesCount: session.chatMessagesCount,
    };

    return report;
  }
}
```

### 4. Chat Module

#### Chat Gateway
```typescript
@WebSocketGateway()
export class ChatGateway {
  @SubscribeMessage('send-message')
  async handleMessage(
    @MessageBody() data: SendMessageDto,
    @ConnectedSocket() client: Socket,
  ) {
    const message = await this.chatService.saveMessage({
      sessionId: data.sessionId,
      senderId: data.senderId,
      content: data.content,
      messageType: data.messageType || 'text',
    });

    // Broadcast to all users in the session
    this.server.to(`session-${data.sessionId}`).emit('new-message', message);

    return { success: true, message };
  }

  @SubscribeMessage('get-messages')
  async handleGetMessages(
    @MessageBody() data: GetMessagesDto,
  ) {
    const messages = await this.chatService.getSessionMessages(
      data.sessionId,
      data.limit,
      data.offset,
    );

    return { success: true, messages };
  }
}
```

#### Chat Service
```typescript
@Injectable()
export class ChatService {
  constructor(
    @InjectRepository(ChatMessage)
    private messageRepository: Repository<ChatMessage>,
  ) {}

  async saveMessage(data: CreateMessageDto): Promise<ChatMessage> {
    const message = this.messageRepository.create({
      sessionId: data.sessionId,
      senderId: data.senderId,
      content: data.content,
      messageType: data.messageType,
      createdAt: new Date(),
    });

    return this.messageRepository.save(message);
  }

  async getSessionMessages(
    sessionId: string,
    limit: number = 50,
    offset: number = 0,
  ): Promise<ChatMessage[]> {
    return this.messageRepository.find({
      where: { sessionId, isDeleted: false },
      relations: ['sender'],
      order: { createdAt: 'DESC' },
      take: limit,
      skip: offset,
    });
  }
}
```

### 5. Admin Module

#### Admin Service
```typescript
@Injectable()
export class AdminService {
  constructor(
    @InjectRepository(User)
    private userRepository: Repository<User>,
    @InjectRepository(Class)
    private classRepository: Repository<Class>,
    @InjectRepository(Student)
    private studentRepository: Repository<Student>,
  ) {}

  async createTeacher(createTeacherDto: CreateTeacherDto): Promise<Teacher> {
    // Generate unique code for teacher
    const code = await this.generateUniqueCode('TCH');
    
    const user = this.userRepository.create({
      code,
      fullName: createTeacherDto.fullName,
      phoneNumber: createTeacherDto.phoneNumber,
      email: createTeacherDto.email,
      password: await bcrypt.hash(createTeacherDto.password, 10),
      role: 'teacher',
    });

    const savedUser = await this.userRepository.save(user);

    const teacher = this.teacherRepository.create({
      userId: savedUser.id,
      specialization: createTeacherDto.specialization,
      experienceYears: createTeacherDto.experienceYears,
      bio: createTeacherDto.bio,
    });

    return this.teacherRepository.save(teacher);
  }

  async createClass(createClassDto: CreateClassDto): Promise<Class> {
    // Validate teacher exists
    const teacher = await this.teacherRepository.findOne({
      where: { id: createClassDto.teacherId },
    });

    if (!teacher) {
      throw new NotFoundException('Teacher not found');
    }

    // Generate unique class code
    const code = await this.generateUniqueCode('CLS');

    const classEntity = this.classRepository.create({
      name: createClassDto.name,
      code,
      teacherId: createClassDto.teacherId,
      description: createClassDto.description,
      subject: createClassDto.subject,
      maxStudents: createClassDto.maxStudents || 50,
    });

    const savedClass = await this.classRepository.save(classEntity);

    // Enroll students
    if (createClassDto.studentIds && createClassDto.studentIds.length > 0) {
      await this.enrollStudents(savedClass.id, createClassDto.studentIds);
    }

    return savedClass;
  }

  async searchStudents(searchQuery: string): Promise<Student[]> {
    return this.studentRepository
      .createQueryBuilder('student')
      .leftJoinAndSelect('student.user', 'user')
      .where('user.fullName ILIKE :query', { query: `%${searchQuery}%` })
      .orWhere('user.code ILIKE :query', { query: `%${searchQuery}%` })
      .orWhere('user.phoneNumber ILIKE :query', { query: `%${searchQuery}%` })
      .getMany();
  }

  private async generateUniqueCode(prefix: string): Promise<string> {
    let code: string;
    let exists = true;

    while (exists) {
      const randomNum = Math.floor(Math.random() * 10000)
        .toString()
        .padStart(4, '0');
      code = `${prefix}${randomNum}`;

      const existing = await this.userRepository.findOne({
        where: { code },
      });

      exists = !!existing;
    }

    return code;
  }
}
```

### 6. Security Configuration

#### Security Middleware
```typescript
export class SecurityMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    // Rate limiting
    const rateLimit = require('express-rate-limit');
    const limiter = rateLimit({
      windowMs: 15 * 60 * 1000, // 15 minutes
      max: 100, // limit each IP to 100 requests per windowMs
      message: 'Too many requests from this IP',
    });

    // Security headers
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Frame-Options', 'DENY');
    res.setHeader('X-XSS-Protection', '1; mode=block');
    res.setHeader('Strict-Transport-Security', 'max-age=31536000; includeSubDomains');

    limiter(req, res, next);
  }
}
```

#### File Upload Validation
```typescript
@Injectable()
export class FileUploadService {
  private readonly allowedMimeTypes = [
    'video/webm',
    'video/mp4',
    'video/avi',
    'application/pdf',
    'image/jpeg',
    'image/png',
  ];

  private readonly maxFileSize = 500 * 1024 * 1024; // 500MB

  async validateFile(file: Express.Multer.File): Promise<boolean> {
    // Check file type
    if (!this.allowedMimeTypes.includes(file.mimetype)) {
      throw new BadRequestException('Invalid file type');
    }

    // Check file size
    if (file.size > this.maxFileSize) {
      throw new BadRequestException('File too large');
    }

    // Scan for malware (if antivirus service available)
    if (await this.containsMalware(file.buffer)) {
      throw new BadRequestException('File contains malware');
    }

    return true;
  }

  private async containsMalware(buffer: Buffer): Promise<boolean> {
    // Implement malware scanning logic
    return false;
  }
}
```

## API Documentation

### Authentication Endpoints
- `POST /auth/login` - User login
- `POST /auth/refresh` - Refresh JWT token
- `POST /auth/logout` - User logout

### Teacher Endpoints
- `GET /teacher/classes` - Get teacher's classes
- `POST /teacher/sessions/start` - Start new session
- `PUT /teacher/sessions/:id/pause` - Pause session
- `PUT /teacher/sessions/:id/resume` - Resume session
- `POST /teacher/sessions/:id/recording/start` - Start recording
- `POST /teacher/sessions/:id/recording/stop` - Stop recording
- `POST /teacher/grades` - Add student grades

### Student Endpoints
- `GET /student/classes` - Get student's classes
- `POST /student/sessions/:id/join` - Join session
- `POST /student/sessions/:id/request-speak` - Request to speak
- `GET /student/sessions/:id/recording` - Get session recording

### Admin Endpoints
- `POST /admin/teachers` - Create teacher
- `POST /admin/students` - Create student
- `POST /admin/classes` - Create class
- `GET /admin/reports` - Generate reports
- `POST /admin/whatsapp/send` - Send WhatsApp messages

This backend architecture provides a secure, scalable, and maintainable foundation for the educational platform with comprehensive real-time communication capabilities.