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
import { AttendanceService } from '../attendance/attendance.service';
import { MediasoupService } from '../mediasoup/mediasoup.service';
import * as mediasoup from 'mediasoup';
import { RedisService } from '../redis/redis.service';
import Redis from 'ioredis';

@WebSocketGateway({
  cors: {
    origin: '*', // Allow connections from any origin for development
  },
})
export class ClassroomGateway {
  @WebSocketServer()
  server: Server;

  private readonly rooms = new Map<string, mediasoup.types.Router>();
  private readonly transports = new Map<string, any>();
  private readonly producers = new Map<string, any>();
  private readonly redisClient: Redis;

  constructor(
    private readonly chatService: ChatService,
    private readonly usersService: UsersService,
    private readonly classesService: ClassesService,
    private readonly attendanceService: AttendanceService,
    private readonly mediasoupService: MediasoupService,
    private readonly redisService: RedisService,
  ) {
    this.redisClient = this.redisService.getClient();
  }

  handleConnection(client: Socket) {
    console.log(`Client connected: ${client.id}`);
  }

  async handleDisconnect(client: Socket) {
    console.log(`Client disconnected: ${client.id}`);
    const clientKey = `client:${client.id}`;
    const clientInfo = await this.redisClient.hgetall(clientKey);

    if (clientInfo && clientInfo.userId && clientInfo.classId) {
      const { userId, classId } = clientInfo;
      const attendanceKey = `attendance:${classId}`;

      await this.redisClient.srem(attendanceKey, userId);
      await this.redisClient.del(clientKey);

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

  @SubscribeMessage('join-room')
  async handleJoinRoom(
    @MessageBody() data: { classId: string; userId: string; fullName: string },
    @ConnectedSocket() client: Socket,
  ): Promise<void> {
    console.log(`Client ${client.id} (${data.fullName}) is joining room ${data.classId}`);
    client.join(data.classId);

    const { classId, userId, fullName } = data;
    const clientKey = `client:${client.id}`;
    const attendanceKey = `attendance:${classId}`;

    // Track attendance and client info in Redis
    await this.redisClient.sadd(attendanceKey, userId);
    await this.redisClient.hset(clientKey, { classId, userId });

    // Record event in DB
    const user = await this.usersService.findOneById(userId);
    const classEntity = await this.classesService.findOne(classId);
    if (user && classEntity) {
      this.attendanceService.recordEvent(user, classEntity, 'joined' as any);
    }

    // Notify the room that a new user has joined
    this.server.to(classId).emit('user-joined', { userId, fullName });

    // Send the current attendance list to the newly joined client
    const currentAttendance = await this.redisClient.smembers(attendanceKey);
    client.emit('current-attendance', currentAttendance);

    // Create a mediasoup router for the room if it doesn't exist
    if (!this.rooms.has(data.classId)) {
      const worker = this.mediasoupService.getWorker();
      const router = await worker.createRouter({
        mediaCodecs: [
          // Define the codecs you want to support
          {
            kind: 'audio',
            mimeType: 'audio/opus',
            clockRate: 48000,
            channels: 2,
          },
          {
            kind: 'video',
            mimeType: 'video/VP8',
            clockRate: 90000,
            parameters: {
              'x-google-start-bitrate': 1000,
            },
          },
        ],
      });
      this.rooms.set(data.classId, router);
      console.log(`Mediasoup router created for room ${data.classId}`);
    }
  }

  @SubscribeMessage('chat-message')
  async handleChatMessage(
    @MessageBody() data: { classId: string; message: string; userId: string },
    @ConnectedSocket() client: Socket,
  ): Promise<void> {
    const user = await this.usersService.findOneById(data.userId);
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

  // --- Mediasoup Signaling Handlers ---

  @SubscribeMessage('get-router-rtp-capabilities')
  handleGetRouterRtpCapabilities(
    @MessageBody() data: { classId: string },
    @ConnectedSocket() client: Socket,
  ) {
    const router = this.rooms.get(data.classId);
    if (router) {
      client.emit('router-rtp-capabilities', router.rtpCapabilities);
    }
  }

  @SubscribeMessage('create-transport')
  async handleCreateTransport(
    @MessageBody() data: { classId: string, isProducer: boolean },
    @ConnectedSocket() client: Socket,
  ) {
    try {
      const router = this.rooms.get(data.classId);
      if (!router) {
        throw new Error(`Router for class ${data.classId} not found`);
      }

      const transport = await router.createWebRtcTransport({
        listenIps: [{ ip: '0.0.0.0', announcedIp: '127.0.0.1' }], // Replace with public IP in production
        enableUdp: true,
        enableTcp: true,
        preferUdp: true,
      });

      // Store the transport server-side
      this.transports.set(transport.id, transport);

      client.emit('transport-created', {
        id: transport.id,
        iceParameters: transport.iceParameters,
        iceCandidates: transport.iceCandidates,
        dtlsParameters: transport.dtlsParameters,
      });

    } catch (error) {
      console.error('Error creating transport:', error);
      client.emit('error', 'Error creating transport');
    }
  }

  @SubscribeMessage('connect-transport')
  async handleConnectTransport(
    @MessageBody() data: { classId: string; transportId: string; dtlsParameters: any },
    @ConnectedSocket() client: Socket,
  ) {
    try {
      const transport = this.transports.get(data.transportId);
      if (!transport) {
        throw new Error(`Transport with id ${data.transportId} not found`);
      }
      await transport.connect({ dtlsParameters: data.dtlsParameters });
      client.emit('transport-connected');
    } catch (error) {
      console.error('Error connecting transport:', error);
      client.emit('error', 'Error connecting transport');
    }
  }

  @SubscribeMessage('produce')
  async handleProduce(
    @MessageBody() data: { classId: string; transportId: string; kind: any; rtpParameters: any },
    @ConnectedSocket() client: Socket,
  ) {
    try {
      const transport = this.transports.get(data.transportId);
      if (!transport) {
        throw new Error(`Transport with id ${data.transportId} not found`);
      }
      const producer = await transport.produce({
        kind: data.kind,
        rtpParameters: data.rtpParameters,
      });

      if (producer.kind === 'audio') {
        producer.setPriority(10); // High priority for audio
      }

      this.producers.set(producer.id, producer);

      client.emit('produced', { id: producer.id });

      // Notify other clients in the room about the new producer
      client.to(data.classId).emit('new-producer', { producerId: producer.id });

    } catch (error) {
      console.error('Error producing:', error);
      client.emit('error', 'Error producing');
    }
  }

  @SubscribeMessage('consume')
  async handleConsume(
    @MessageBody() data: { classId: string; transportId: string; producerId: string; rtpCapabilities: any },
    @ConnectedSocket() client: Socket,
  ) {
    try {
      const router = this.rooms.get(data.classId);
      if (!router || !router.canConsume({ producerId: data.producerId, rtpCapabilities: data.rtpCapabilities })) {
        throw new Error('Cannot consume');
      }
      const transport = this.transports.get(data.transportId);
      if (!transport) {
        throw new Error(`Transport with id ${data.transportId} not found`);
      }
      const consumer = await transport.consume({
        producerId: data.producerId,
        rtpCapabilities: data.rtpCapabilities,
        paused: true, // Start paused
      });

      // Store consumer server-side, and associate with client

      client.emit('consumed', {
        id: consumer.id,
        producerId: consumer.producerId,
        kind: consumer.kind,
        rtpParameters: consumer.rtpParameters,
      });
    } catch (error) {
      console.error('Error consuming:', error);
      client.emit('error', 'Error consuming');
    }
  }

  @SubscribeMessage('set-audio-mode')
  handleSetAudioMode(
    @MessageBody() data: { classId: string; isFreeMicMode: boolean },
    @ConnectedSocket() client: Socket,
  ): void {
    // Broadcast the new audio mode to everyone else in the room
    client.to(data.classId).emit('audio-mode-changed', {
      isFreeMicMode: data.isFreeMicMode,
    });
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

  @SubscribeMessage('session-state-changed')
  handleSessionStateChanged(
    @MessageBody() data: { classId: string; isPaused: boolean },
    @ConnectedSocket() client: Socket,
  ): void {
    client.to(data.classId).emit('session-state-changed', {
      isPaused: data.isPaused,
    });
  }

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
