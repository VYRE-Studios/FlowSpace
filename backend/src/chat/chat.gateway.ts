import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import { OnModuleInit, UnauthorizedException } from '@nestjs/common';
import { Server, Socket } from 'socket.io';

import { KratosService } from '../auth/kratos.service';
import { RedisService } from '../shared/redis.service';
import {
  WorkspaceEvents,
  ChatMessagePayload,
  ChannelCreatedPayload,
} from '../../libs/shared';

@WebSocketGateway({ cors: true })
export class ChatGateway implements OnModuleInit {
  @WebSocketServer()
  server!: Server;

  constructor(
    private readonly redis: RedisService,
    private readonly kratos: KratosService,
  ) {}

  async onModuleInit() {
    await this.redis.subscribe(
      [WorkspaceEvents.MESSAGE_SENT, WorkspaceEvents.CHANNEL_CREATED],
      (channel: string, payload: string) => {
        switch (channel) {
          case WorkspaceEvents.MESSAGE_SENT: {
            const data = JSON.parse(payload) as {
              workspaceId: string;
              message: ChatMessagePayload;
            };

            this.server.to(data.message.channelId).emit('message.new', data.message);
            this.server
              .to(`workspace:${data.workspaceId}`)
              .emit('workspace.activity', { type: 'message', message: data.message });
            break;
          }
          case WorkspaceEvents.CHANNEL_CREATED: {
            const data = JSON.parse(payload) as ChannelCreatedPayload;
            this.server
              .to(`workspace:${data.workspaceId}`)
              .emit('channel.created', data);
            break;
          }
          default:
            break;
        }
      },
    );
  }

  async handleConnection(client: Socket) {
    try {
      const payload = await this.extractUser(client);
      client.data.user = payload;
    } catch (error) {
      client.disconnect(true);
      return;
    }

    const workspaceId = client.handshake.query.workspaceId as string | undefined;
    const channelId = client.handshake.query.channelId as string | undefined;

    if (!workspaceId) {
      client.disconnect(true);
      return;
    }

    client.join(`workspace:${workspaceId}`);

    if (channelId) {
      client.join(channelId);
    }
  }

  @SubscribeMessage('channel.join')
  handleJoin(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { channelId: string },
  ) {
    client.join(data.channelId);
  }

  @SubscribeMessage('channel.leave')
  handleLeave(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { channelId: string },
  ) {
    client.leave(data.channelId);
  }

  private async extractUser(
    client: Socket,
  ): Promise<{
    id: string;
    email: string;
    displayName: string;
    identity: Record<string, any>;
    session: Record<string, any>;
  }> {
    const sessionToken =
      (client.handshake.auth?.sessionToken as string | undefined) ??
      (client.handshake.query.sessionToken as string | undefined);
    const cookie = client.handshake.headers?.cookie as string | undefined;

    if (!sessionToken && !cookie) {
      throw new UnauthorizedException('Missing session token');
    }

    const session = await this.kratos.whoAmI({
      sessionToken,
      cookie,
    });

    const identity = session.identity ?? {};
    const traits = (identity.traits ?? {}) as Record<string, any>;
    const email =
      traits['email'] ??
      traits['email_address'] ??
      traits['username'] ??
      identity.id;
    const displayName =
      traits['display_name'] ??
      traits['name'] ??
      traits['full_name'] ??
      email;

    return {
      id: identity.id,
      email,
      displayName,
      identity,
      session,
    };
  }
}