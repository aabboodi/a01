import {
  WebSocketGateway,
  SubscribeMessage,
  MessageBody,
  WebSocketServer,
  ConnectedSocket,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';

@WebSocketGateway({
  cors: {
    origin: '*', // Allow connections from any origin for development
  },
})
export class ClassroomGateway {
  @WebSocketServer()
  server: Server;

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
  handleChatMessage(
    @MessageBody() data: { classId: string; message: string },
    @ConnectedSocket() client: Socket,
  ): void {
    // Broadcast the message to all other clients in the same room
    client.to(data.classId).emit('chat-message', {
      message: data.message,
      senderId: client.id, // Identify the sender
    });
  }

  // --- WebRTC Signaling Handlers ---

  @SubscribeMessage('webrtc-offer')
  handleWebrtcOffer(
    @MessageBody() data: { classId: string; offer: any },
    @ConnectedSocket() client: Socket,
  ): void {
    // Broadcast the offer to all other clients in the room
    client.to(data.classId).emit('webrtc-offer', {
      offer: data.offer,
      senderId: client.id,
    });
  }

  @SubscribeMessage('webrtc-answer')
  handleWebrtcAnswer(
    @MessageBody() data: { classId: string; answer: any },
    @ConnectedSocket() client: Socket,
  ): void {
    // Broadcast the answer to all other clients in the room
    client.to(data.classId).emit('webrtc-answer', {
      answer: data.answer,
      senderId: client.id,
    });
  }

  @SubscribeMessage('webrtc-ice-candidate')
  handleWebrtcIceCandidate(
    @MessageBody() data: { classId: string; candidate: any },
    @ConnectedSocket() client: Socket,
  ): void {
    // Broadcast the ICE candidate to all other clients in the room
    client.to(data.classId).emit('webrtc-ice-candidate', {
      candidate: data.candidate,
      senderId: client.id,
    });
  }
}
