import {
  ConnectedSocket,
  MessageBody,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import {
  BadRequestException,
  OnModuleInit,
  UnauthorizedException,
} from '@nestjs/common';
import { Server, Socket } from 'socket.io';

import { KratosService } from '../auth/kratos.service';
import { RedisService } from '../shared/redis.service';
import { WorkspaceEvents } from '../../libs/shared';

interface PresenceMessage {
  workspaceId: string;
  userId: string;
  status: 'online' | 'offline' | 'away';
  lastActiveAt: string;
}

@WebSocketGateway({ cors: true, namespace: 'presence' })
export class PresenceGateway implements OnModuleInit {
  private static readonly TTL_SECONDS = 60;

  @WebSocketServer()
  server!: Server;

  constructor(
    private readonly redis: RedisService,
    private readonly kratos: KratosService,
  ) {}

  async onModuleInit() {
    await this.redis.subscribe(
      [WorkspaceEvents.PRESENCE_UPDATE],
      (channel: string, payload: string) => {
        if (channel !== WorkspaceEvents.PRESENCE_UPDATE) {
          return;
        }

        const message = JSON.parse(payload) as PresenceMessage;
        this.server
          .to(`workspace:${message.workspaceId}`)
          .emit('presence.update', message);
      },
    );
  }

  async handleConnection(client: Socket) {
    let user:
      | {
          id: string;
          email: string;
          displayName: string;
          identity: Record<string, any>;
          session: Record<string, any>;
        }
      | undefined;
    try {
      user = await this.extractUser(client);
    } catch (error) {
      client.disconnect(true);
      return;
    }

    client.data.user = user;

    const workspaceId = client.handshake.query.workspaceId as string | undefined;
    if (!workspaceId) {
      client.disconnect(true);
      return;
    }

    client.join(`workspace:${workspaceId}`);
    void this.setStatus(workspaceId, user.id, 'online');
  }

  handleDisconnect(client: Socket) {
    const workspaceId = client.handshake.query.workspaceId as string | undefined;
    const user = client.data.user as
      | {
          id: string;
          email: string;
          displayName: string;
        }
      | undefined;

    if (!workspaceId || !user) {
      return;
    }

    void this.setStatus(workspaceId, user.id, 'offline');
  }

  @SubscribeMessage('channel.join')
  handleChannelJoin(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { channelId: string },
  ) {
    client.join(data.channelId);
  }

  @SubscribeMessage('channel.leave')
  handleChannelLeave(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: { channelId: string },
  ) {
    client.leave(data.channelId);
  }

  @SubscribeMessage('heartbeat')
  async handleHeartbeat(
    @ConnectedSocket() client: Socket,
    @MessageBody()
    data: {
      status?: 'online' | 'offline' | 'away';
    },
  ) {
    const workspaceId = client.handshake.query.workspaceId as string | undefined;
    const user = client.data.user as
      | {
          id: string;
          email: string;
          displayName: string;
        }
      | undefined;

    if (!workspaceId || !user) {
      throw new BadRequestException('workspaceId and token are required');
    }

    await this.setStatus(workspaceId, user.id, data.status ?? 'online');
  }

  @SubscribeMessage('typing')
  handleTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() body: { channelId: string; typing: boolean },
  ) {
    const workspaceId = client.handshake.query.workspaceId as string | undefined;
    const user = client.data.user as
      | {
          id: string;
          email: string;
          displayName: string;
        }
      | undefined;

    if (!workspaceId || !user) {
      return;
    }

    this.server
      .to(body.channelId)
      .emit('typing', {
        userId: user.id,
        typing: body.typing,
        channelId: body.channelId,
      });
  }

  private async setStatus(
    workspaceId: string,
    userId: string,
    status: 'online' | 'offline' | 'away',
  ) {
    const key = `presence:${workspaceId}:${userId}`;
    const publisher = this.redis.getPublisher();

    await publisher.set(key, status, 'EX', PresenceGateway.TTL_SECONDS);

    const payload: PresenceMessage = {
      workspaceId,
      userId,
      status,
      lastActiveAt: new Date().toISOString(),
    };

    await this.redis.publish(WorkspaceEvents.PRESENCE_UPDATE, payload);
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