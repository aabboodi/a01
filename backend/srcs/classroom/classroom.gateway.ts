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

  // We will add more handlers here for WebRTC signaling later.
  // For example: @SubscribeMessage('offer'), @SubscribeMessage('answer'), etc.
}
