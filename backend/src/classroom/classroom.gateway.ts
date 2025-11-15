import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  WebSocketServer,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { ChatService } from '../chat/chat.service';
import { UsersService } from '../users/users.service';
import { ClassesService } from '../classes/classes.service';

@WebSocketGateway({
  cors: {
    origin: '*', // Allow connections from any origin for development
  },
})
export class ClassroomGateway {
  @WebSocketServer()
  server: Server;

  // classId -> (userId -> { fullName })
  private readonly attendance = new Map<string, Map<string, { fullName: string }>>();
  // clientId -> { classId, userId }
  private readonly clients = new Map<string, { classId: string; userId: string }>();

  constructor(
    private readonly chatService: ChatService,
    private readonly usersService: UsersService,
    private readonly classesService: ClassesService,
    private readonly attendanceService: AttendanceService,
  ) {}

  handleConnection(client: Socket) {
    console.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
    const clientInfo = this.clients.get(client.id);
    if (clientInfo) {
      const { classId, userId } = clientInfo;
      const classAttendance = this.attendance.get(classId);
      if (classAttendance) {
        classAttendance.delete(userId);
        this.clients.delete(client.id);

        // Notify room that user has left
        this.server.to(classId).emit('user-left', { userId });

        // Record event in DB
        const user = await this.usersService.findOneById(userId);
        const classEntity = await this.classesService.findOne(classId);
        if (user && classEntity) {
          this.attendanceService.recordEvent(user, classEntity, 'left' as any);
        }
      }
    }
  }

  @SubscribeMessage('join-room')
  handleJoinRoom(
    @MessageBody() data: { classId: string; userId: string; fullName: string },
    @ConnectedSocket() client: Socket,
  ): void {
    console.log(`Client ${client.id} (${data.fullName}) is joining room ${data.classId}`);
    client.join(data.classId);

    // Track attendance
    if (!this.attendance.has(data.classId)) {
      this.attendance.set(data.classId, new Map());
    }
    this.attendance.get(data.classId)!.set(data.userId, { fullName: data.fullName });
    this.clients.set(client.id, { classId: data.classId, userId: data.userId });

    // Record event in DB
    const user = await this.usersService.findOneById(data.userId);
    const classEntity = await this.classesService.findOne(data.classId);
    if (user && classEntity) {
      this.attendanceService.recordEvent(user, classEntity, 'joined' as any);
    }

    // Notify the room that a new user has joined
    this.server.to(data.classId).emit('user-joined', { userId: data.userId, fullName: data.fullName });

    // Send the current attendance list to the newly joined client
    const currentAttendance = Array.from(this.attendance.get(data.classId)!.keys());
    client.emit('current-attendance', currentAttendance);
  }

  @SubscribeMessage('chat-message')
  async handleChatMessage(
    @MessageBody() data: { classId: string; message: string; userId: string },
    @ConnectedSocket() client: Socket,
  ): Promise<void> {
    const user = await this.usersService.findById(data.userId);
    const classEntity = await this.classesService.findOne(data.classId);

    if (user && classEntity) {
      const chatMessage = await this.chatService.createMessage(
        data.message,
        user,
        classEntity,
      );

      // Broadcast the saved message, now including user info
      this.server.to(data.classId).emit('chat-message', {
        message: chatMessage.message,
        senderId: client.id,
        user: {
          user_id: user.user_id,
          full_name: user.full_name,
        }
      });
    } else {
      console.error(`User or Class not found for chat message:`, data);
    }
  }

  // --- WebRTC Signaling Handlers (Now supports targeted signaling) ---

  @SubscribeMessage('webrtc-offer')
  handleWebrtcOffer(
    @MessageBody() data: { classId: string; offer: any; targetId?: string },
    @ConnectedSocket() client: Socket,
  ): void {
    const payload = { offer: data.offer, senderId: client.id };
    if (data.targetId) {
      // Send to a specific client if a target is provided (student to teacher)
      this.server.to(data.targetId).emit('webrtc-offer', payload);
    } else {
      // Otherwise, broadcast to the room (teacher's initial broadcast)
      client.to(data.classId).emit('webrtc-offer', payload);
    }
  }

  @SubscribeMessage('webrtc-answer')
  handleWebrtcAnswer(
    @MessageBody() data: { classId: string; answer: any; targetId: string },
    @ConnectedSocket() client: Socket,
  ): void {
    // Answers are always targeted to a specific client
    this.server.to(data.targetId).emit('webrtc-answer', {
      answer: data.answer,
      senderId: client.id,
    });
  }

  @SubscribeMessage('webrtc-ice-candidate')
  handleWebrtcIceCandidate(
    @MessageBody() data: { classId: string; candidate: any; targetId?: string },
    @ConnectedSocket() client: Socket,
  ): void {
    const payload = { candidate: data.candidate, senderId: client.id };
    if (data.targetId) {
      // Send to a specific client
      this.server.to(data.targetId).emit('webrtc-ice-candidate', payload);
    } else {
      // Broadcast to the room
      client.to(data.classId).emit('webrtc-ice-candidate', payload);
    }
  }

  @SubscribeMessage('request-to-speak')
  handleRequestToSpeak(
    @MessageBody() data: { classId: string; studentId: string; studentName: string },
    @ConnectedSocket() client: Socket,
  ): void {
    // Broadcast the request to other clients in the room (i.e., the teacher)
    client.to(data.classId).emit('request-to-speak', {
      studentId: data.studentId,
      studentName: data.studentName,
      socketId: client.id,
    });
  }

  @SubscribeMessage('allow-to-speak')
  handleAllowToSpeak(
    @MessageBody() data: { studentSocketId: string },
    @ConnectedSocket() client: Socket,
  ): void {
    // Notify the specific student that they have permission to speak
    this.server.to(data.studentSocketId).emit('permission-to-speak', {
      teacherSocketId: client.id,
    });
  }

  // --- Whiteboard Drawing Handler ---

  @SubscribeMessage('draw-event')
  handleDrawEvent(
    @MessageBody() data: { classId: string; event: any },
    @ConnectedSocket() client: Socket,
  ): void {
    // Broadcast the drawing event to all other clients in the same room
    client.to(data.classId).emit('draw-event', {
      event: data.event,
      senderId: client.id,
    });
  }
}
