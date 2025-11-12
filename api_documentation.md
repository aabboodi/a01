# API Documentation & WebRTC Implementation Plan

## WebRTC Implementation Architecture

### Signaling Flow
```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Teacher   │     │   Signaling │     │   Student   │
│   Client    │◄───►│   Server    │◄───►│   Client    │
└─────────────┘     └─────────────┘     └─────────────┘
       │                    │                    │
       │                    │                    │
       ▼                    ▼                    ▼
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   WebRTC    │     │   Socket.io │     │   WebRTC    │
│   Peer      │     │   Events    │     │   Peer      │
│ Connection  │     │   Handler   │     │ Connection  │
└─────────────┘     └─────────────┘     └─────────────┘
```

### WebRTC Configuration
```typescript
export const WEBRTC_CONFIG = {
  iceServers: [
    { urls: 'stun:stun.l.google.com:19302' },
    { urls: 'stun:stun1.l.google.com:19302' },
    {
      urls: 'turn:your-turn-server.com:3478',
      username: 'turnuser',
      credential: 'turnpassword',
    },
  ],
  iceCandidatePoolSize: 10,
  bundlePolicy: 'max-bundle',
  rtcpMuxPolicy: 'require',
};

export const MEDIA_CONSTRAINTS = {
  video: {
    width: { ideal: 1280, max: 1920 },
    height: { ideal: 720, max: 1080 },
    frameRate: { ideal: 30, max: 60 },
    facingMode: 'user',
  },
  audio: {
    echoCancellation: true,
    noiseSuppression: true,
    autoGainControl: true,
  },
};

export const SCREEN_SHARE_CONSTRAINTS = {
  video: {
    cursor: 'always',
    resizeMode: 'crop-and-scale',
  },
  audio: {
    echoCancellation: true,
    noiseSuppression: true,
  },
};
```

## Detailed API Endpoints

### 1. Authentication APIs

#### User Login
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "code": "TCH1001",
  "password": "userpassword"
}

Response:
{
  "success": true,
  "data": {
    "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "uuid",
      "code": "TCH1001",
      "fullName": "أحمد محمد",
      "role": "teacher",
      "profileImage": "https://..."
    }
  }
}
```

#### Refresh Token
```http
POST /api/v1/auth/refresh
Content-Type: application/json

{
  "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

#### Logout
```http
POST /api/v1/auth/logout
Authorization: Bearer {accessToken}
```

### 2. Teacher APIs

#### Get Teacher Classes
```http
GET /api/v1/teacher/classes
Authorization: Bearer {accessToken}

Response:
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "الرياضيات - الصف الأول",
      "code": "CLS2001",
      "subject": "الرياضيات",
      "studentsCount": 25,
      "nextSession": "2025-11-15T10:00:00Z",
      "isActive": true
    }
  ]
}
```

#### Start Session
```http
POST /api/v1/teacher/sessions/start
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "classId": "uuid",
  "topic": "الجبر الخطي",
  "duration": 60
}

Response:
{
  "success": true,
  "data": {
    "sessionId": "uuid",
    "sessionCode": "SES3001",
    "startTime": "2025-11-15T10:00:00Z",
    "joinUrl": "https://app.almafd.edu/session/SES3001"
  }
}
```

#### Control Session
```http
PUT /api/v1/teacher/sessions/{sessionId}/pause
Authorization: Bearer {accessToken}

PUT /api/v1/teacher/sessions/{sessionId}/resume
Authorization: Bearer {accessToken}

PUT /api/v1/teacher/sessions/{sessionId}/end
Authorization: Bearer {accessToken}
```

#### Recording Control
```http
POST /api/v1/teacher/sessions/{sessionId}/recording/start
Authorization: Bearer {accessToken}

Response:
{
  "success": true,
  "data": {
    "recordingId": "uuid",
    "status": "recording",
    "startTime": "2025-11-15T10:05:00Z"
  }
}

POST /api/v1/teacher/sessions/{sessionId}/recording/stop
Authorization: Bearer {accessToken}

Response:
{
  "success": true,
  "data": {
    "recordingId": "uuid",
    "status": "processing",
    "duration": 3600,
    "fileSize": "150MB",
    "downloadUrl": "https://recordings.almafd.edu/..."
  }
}
```

#### Student Permission Control
```http
POST /api/v1/teacher/sessions/{sessionId}/students/{studentId}/allow-speech
Authorization: Bearer {accessToken}

POST /api/v1/teacher/sessions/{sessionId}/students/{studentId}/deny-speech
Authorization: Bearer {accessToken}

POST /api/v1/teacher/sessions/{sessionId}/students/mute-all
Authorization: Bearer {accessToken}
```

#### Add Grades
```http
POST /api/v1/teacher/grades
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "classId": "uuid",
  "studentId": "uuid",
  "grades": [
    {
      "component": "class_interaction",
      "marks": 6,
      "maxMarks": 7,
      "comments": "مشاركة ممتازة"
    },
    {
      "component": "homework",
      "marks": 7,
      "maxMarks": 7,
      "comments": "جميع الواجبات مكتملة"
    },
    {
      "component": "oral_exam",
      "marks": 55,
      "maxMarks": 60,
      "comments": "أداء جيد"
    }
  ]
}

Response:
{
  "success": true,
  "data": {
    "studentId": "uuid",
    "studentName": "سارة أحمد",
    "finalGrade": 85.5,
    "gradeBreakdown": {
      "class_interaction": 6,
      "homework": 7,
      "oral_exam": 55,
      "written_exam": 6,
      "final_grade": 85.5
    }
  }
}
```

### 3. Student APIs

#### Get Student Classes
```http
GET /api/v1/student/classes
Authorization: Bearer {accessToken}

Response:
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "name": "الرياضيات - الصف الأول",
      "teacherName": "أحمد محمد",
      "subject": "الرياضيات",
      "nextSession": "2025-11-15T10:00:00Z",
      "unreadMessages": 3,
      "grade": 85.5
    }
  ]
}
```

#### Join Session
```http
POST /api/v1/student/sessions/{sessionId}/join
Authorization: Bearer {accessToken}

Response:
{
  "success": true,
  "data": {
    "sessionId": "uuid",
    "sessionCode": "SES3001",
    "teacherName": "أحمد محمد",
    "topic": "الجبر الخطي",
    "joinTime": "2025-11-15T10:02:00Z",
    "webrtcConfig": {
      "iceServers": [...],
      "iceCandidatePoolSize": 10
    }
  }
}
```

#### Request to Speak
```http
POST /api/v1/student/sessions/{sessionId}/request-speak
Authorization: Bearer {accessToken}

Response:
{
  "success": true,
  "data": {
    "requestId": "uuid",
    "status": "pending",
    "requestTime": "2025-11-15T10:15:00Z"
  }
}
```

#### Get Session Recording
```http
GET /api/v1/student/sessions/{sessionId}/recording
Authorization: Bearer {accessToken}

Response:
{
  "success": true,
  "data": {
    "recordingId": "uuid",
    "sessionDate": "2025-11-15",
    "duration": 3600,
    "fileUrl": "https://recordings.almafd.edu/...",
    "downloadUrl": "https://recordings.almafd.edu/download/...",
    "expiresAt": "2025-11-22T10:00:00Z"
  }
}
```

### 4. Admin APIs

#### Create Teacher
```http
POST /api/v1/admin/teachers
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "fullName": "محمد علي",
  "phoneNumber": "+966501234567",
  "email": "mohamed.ali@almafd.edu",
  "specialization": "الرياضيات",
  "experienceYears": 10,
  "bio": "معلم رياضيات متخصص في الجبر والهندسة"
}

Response:
{
  "success": true,
  "data": {
    "id": "uuid",
    "code": "TCH1002",
    "fullName": "محمد علي",
    "phoneNumber": "+966501234567",
    "email": "mohamed.ali@almafd.edu",
    "specialization": "الرياضيات",
    "isActive": true,
    "createdAt": "2025-11-15T10:00:00Z"
  }
}
```

#### Create Student
```http
POST /api/v1/admin/students
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "fullName": "فاطمة أحمد",
  "phoneNumber": "+966501112222",
  "age": 16,
  "educationalLevel": "الصف الأول ثانوي",
  "targetLevel": "الصف الثاني ثانوي",
  "parentPhone": "+966503334444"
}

Response:
{
  "success": true,
  "data": {
    "id": "uuid",
    "code": "STU1003",
    "fullName": "فاطمة أحمد",
    "phoneNumber": "+966501112222",
    "age": 16,
    "educationalLevel": "الصف الأول ثانوي",
    "targetLevel": "الصف الثاني ثانوي",
    "isNewStudent": true,
    "createdAt": "2025-11-15T10:00:00Z"
  }
}
```

#### Create Class
```http
POST /api/v1/admin/classes
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "name": "اللغة العربية - الصف الثاني",
  "teacherId": "uuid",
  "subject": "اللغة العربية",
  "description": "صف اللغة العربية للصف الثاني الثانوي",
  "maxStudents": 30,
  "studentIds": ["uuid1", "uuid2", "uuid3"]
}

Response:
{
  "success": true,
  "data": {
    "id": "uuid",
    "name": "اللغة العربية - الصف الثاني",
    "code": "CLS2002",
    "teacherId": "uuid",
    "subject": "اللغة العربية",
    "studentsCount": 3,
    "isActive": true,
    "createdAt": "2025-11-15T10:00:00Z"
  }
}
```

#### Search Students
```http
GET /api/v1/admin/students/search?q=فاطمة
Authorization: Bearer {accessToken}

Response:
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "code": "STU1003",
      "fullName": "فاطمة أحمد",
      "phoneNumber": "+966501112222",
      "age": 16,
      "educationalLevel": "الصف الأول ثانوي",
      "isNewStudent": true,
      "finalGrade": null
    }
  ]
}
```

#### Generate Reports
```http
GET /api/v1/admin/reports?startDate=2025-11-01&endDate=2025-11-15
Authorization: Bearer {accessToken}

Response:
{
  "success": true,
  "data": {
    "sessions": [
      {
        "sessionId": "uuid",
        "className": "الرياضيات - الصف الأول",
        "teacherName": "أحمد محمد",
        "sessionDate": "2025-11-15",
        "duration": 60,
        "studentsPresent": 25,
        "studentsAbsent": 2,
        "averageAttendance": 95.2
      }
    ],
    "summary": {
      "totalSessions": 45,
      "totalTeachers": 5,
      "totalStudents": 120,
      "averageAttendance": 92.5
    }
  }
}
```

#### WhatsApp Integration
```http
POST /api/v1/admin/whatsapp/send
Authorization: Bearer {accessToken}
Content-Type: application/json

{
  "message": "مرحباً، سيبدأ صف الرياضيات غداً في الساعة 10 صباحاً",
  "recipients": ["+966501234567", "+966501112222"],
  "template": "session_reminder"
}

Response:
{
  "success": true,
  "data": {
    "messageId": "uuid",
    "sentCount": 2,
    "failedCount": 0,
    "sentAt": "2025-11-15T10:00:00Z"
  }
}
```

## WebRTC Socket Events

### Client to Server Events
```typescript
// Session Management
socket.emit('join-session', {
  sessionId: 'uuid',
  userId: 'uuid',
  userType: 'teacher' | 'student'
});

// WebRTC Signaling
socket.emit('offer', {
  offer: RTCSessionDescription,
  targetSocketId: 'socket-id'
});

socket.emit('answer', {
  answer: RTCSessionDescription,
  targetSocketId: 'socket-id'
});

socket.emit('ice-candidate', {
  candidate: RTCIceCandidate,
  targetSocketId: 'socket-id'
});

// Audio Controls
socket.emit('request-to-speak', {
  sessionId: 'uuid',
  studentId: 'uuid',
  studentName: 'اسم الطالب'
});

socket.emit('allow-speech', {
  studentSocketId: 'socket-id',
  teacherId: 'uuid'
});

socket.emit('deny-speech', {
  studentSocketId: 'socket-id',
  teacherId: 'uuid'
});

// Chat
socket.emit('send-message', {
  sessionId: 'uuid',
  senderId: 'uuid',
  content: 'نص الرسالة',
  messageType: 'text' | 'file'
});

// Screen Share
socket.emit('start-screen-share', {
  sessionId: 'uuid',
  teacherId: 'uuid'
});

socket.emit('stop-screen-share', {
  sessionId: 'uuid',
  teacherId: 'uuid'
});
```

### Server to Client Events
```typescript
// Session Updates
socket.on('user-joined', (data) => {
  // { userId, userName, userType, socketId }
});

socket.on('user-left', (data) => {
  // { userId, socketId }
});

// WebRTC Signaling
socket.on('offer', (data) => {
  // { offer, senderSocketId }
});

socket.on('answer', (data) => {
  // { answer, senderSocketId }
});

socket.on('ice-candidate', (data) => {
  // { candidate, senderSocketId }
});

// Audio Controls
socket.on('speech-allowed', (data) => {
  // { allowed: true, grantedBy: 'teacher-id' }
});

socket.on('speech-denied', (data) => {
  // { allowed: false, deniedBy: 'teacher-id' }
});

socket.on('student-request', (data) => {
  // { studentId, studentName, requestId }
});

// Chat
socket.on('new-message', (message) => {
  // Chat message object
});

// Session Control
socket.on('session-paused', (data) => {
  // { sessionId, pausedBy: 'teacher-id' }
});

socket.on('session-resumed', (data) => {
  // { sessionId, resumedBy: 'teacher-id' }
});

socket.on('session-ended', (data) => {
  // { sessionId, endedBy: 'teacher-id' }
});

// Screen Share
socket.on('screen-share-started', (data) => {
  // { teacherId, streamId }
});

socket.on('screen-share-stopped', (data) => {
  // { teacherId }
});

// Recording
socket.on('recording-started', (data) => {
  // { recordingId, sessionId, startTime }
});

socket.on('recording-stopped', (data) => {
  // { recordingId, sessionId, duration }
});

// Errors
socket.on('error', (error) => {
  // { code: 'ERROR_CODE', message: 'Error message' }
});
```

## Error Handling

### Error Response Format
```json
{
  "success": false,
  "error": {
    "code": "INVALID_CREDENTIALS",
    "message": "Invalid username or password",
    "details": {
      "field": "password",
      "reason": "incorrect_password"
    }
  }
}
```

### Common Error Codes
- `INVALID_CREDENTIALS` - Login failed
- `SESSION_NOT_FOUND` - Session doesn't exist
- `SESSION_NOT_ACTIVE` - Session is not currently active
- `USER_NOT_AUTHORIZED` - User lacks required permissions
- `MAX_PARTICIPANTS_EXCEEDED` - Session is full
- `RECORDING_NOT_AVAILABLE` - Recording doesn't exist
- `RATE_LIMIT_EXCEEDED` - Too many requests
- `INVALID_FILE_TYPE` - Unsupported file format
- `FILE_TOO_LARGE` - File exceeds size limit

## Security Considerations

### 1. Authentication
- JWT tokens with 15-minute expiration
- Refresh tokens with 7-day expiration
- Token blacklisting on logout
- Rate limiting on auth endpoints

### 2. WebRTC Security
- TURN server authentication
- Encrypted media streams
- Certificate pinning for mobile apps
- Secure signaling channel (WSS)

### 3. File Upload Security
- File type validation
- File size limits
- Malware scanning
- Secure storage (encrypted at rest)

### 4. API Security
- Input validation and sanitization
- SQL injection prevention
- XSS protection
- CORS configuration
- HTTPS enforcement

This comprehensive API and WebRTC implementation plan ensures a secure, scalable, and feature-rich educational platform that meets all the specified requirements.