import {
  WebSocketGateway,
  WebSocketServer,
  SubscribeMessage,
  MessageBody,
  ConnectedSocket,
  OnGatewayConnection,
  OnGatewayDisconnect,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { Logger } from '@nestjs/common';

import { P2PGatewayService } from './p2p-gateway.service';
import { WSIncomingEvent } from './p2p-events.types';

/**
 * WebSocket gateway for P2P communication.
 * Exposes /p2p namespace for Flutter UI to connect to.
 */
@WebSocketGateway({
  namespace: '/p2p',
  cors: {
    origin: '*',
    credentials: true,
  },
})
export class P2PGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(P2PGateway.name);

  constructor(private readonly gatewayService: P2PGatewayService) {}

  handleConnection(client: Socket) {
    this.logger.log(`Client connected: ${client.id}`);
    this.gatewayService.attachServer(this.server);
    
    // Send initial status on connection
    this.gatewayService.sendStatusToClient(client);
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('event')
  async handleEvent(
    @MessageBody() body: WSIncomingEvent,
    @ConnectedSocket() client: Socket,
  ) {
    this.logger.debug(`Received event: ${body.type} from ${client.id}`);
    
    return this.gatewayService.handleIncomingEvent(body, client);
  }
}

