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

  constructor(
    private readonly chatService: ChatService,
    private readonly usersService: UsersService,
    private readonly classesService: ClassesService,
  ) {}

  handleConnection(client: Socket) {
    console.log(`Client connected: ${client.id}`);
  }

  handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('join-room')
  handleJoinRoom(
    @MessageBody() classId: string,
    @ConnectedSocket() client: Socket,
  ): void {
    console.log(`Client ${client.id} is joining room ${classId}`);
    client.join(classId);
    // Acknowledge that the client has joined the room
    client.emit('joined-room', `Successfully joined room ${classId}`);
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
