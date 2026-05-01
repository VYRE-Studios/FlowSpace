import {
  WebSocketGateway,
  WebSocketServer,
  OnGatewayConnection,
  OnGatewayDisconnect,
  ConnectedSocket,
  SubscribeMessage,
} from '@nestjs/websockets';
import { Logger } from '@nestjs/common';
import { Server, Socket } from 'socket.io';

interface UpdateNotification {
  version: string;
  platform: string;
  downloadUrl?: string;
  releaseNotes?: string;
  timestamp: string;
  soundUrl?: string;
}

@WebSocketGateway({ cors: true, namespace: '/updates' })
export class UpdatesGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server!: Server;

  private readonly logger = new Logger(UpdatesGateway.name);
  private connectedClients = new Map<string, { platform: string; version: string }>();

  handleConnection(@ConnectedSocket() client: Socket) {
    const platform = (client.handshake.query.platform as string) || 'windows';
    const version = (client.handshake.query.version as string) || 'unknown';

    this.connectedClients.set(client.id, { platform, version });
    client.join(`platform:${platform}`);

    this.logger.log(
      `[UpdatesGateway] Client connected: ${client.id} (${platform} v${version})`,
    );
  }

  handleDisconnect(@ConnectedSocket() client: Socket) {
    this.connectedClients.delete(client.id);
    this.logger.log(`[UpdatesGateway] Client disconnected: ${client.id}`);
  }

  @SubscribeMessage('ping')
  handlePing(@ConnectedSocket() client: Socket) {
    return { event: 'pong', data: { timestamp: new Date().toISOString() } };
  }

  /**
   * Broadcast update notification to all clients of a specific platform
   */
  notifyUpdateAvailable(
    version: string,
    platform: string,
    downloadUrl?: string,
    releaseNotes?: string,
  ) {
    const notification: UpdateNotification = {
      version,
      platform,
      downloadUrl,
      releaseNotes,
      timestamp: new Date().toISOString(),
      soundUrl: '/assets/sounds/notification.wav',
    };

    this.logger.log(
      `[UpdatesGateway] Broadcasting update v${version} to platform:${platform}`,
    );

    // Broadcast to all clients of the specified platform
    this.server.to(`platform:${platform}`).emit('update.available', notification);

    return {
      notified: this.getClientCountForPlatform(platform),
      notification,
    };
  }

  /**
   * Broadcast update notification to ALL platforms
   */
  notifyUpdateAvailableAll(updates: Array<{ version: string; platform: string; downloadUrl?: string; releaseNotes?: string }>) {
    const results = updates.map((update) =>
      this.notifyUpdateAvailable(
        update.version,
        update.platform,
        update.downloadUrl,
        update.releaseNotes,
      ),
    );

    return {
      total: results.reduce((sum, r) => sum + r.notified, 0),
      byPlatform: results,
    };
  }

  /**
   * Get count of connected clients for a specific platform
   */
  private getClientCountForPlatform(platform: string): number {
    return Array.from(this.connectedClients.values()).filter(
      (client) => client.platform === platform,
    ).length;
  }

  /**
   * Get stats about all connected clients
   */
  getConnectionStats() {
    const stats: Record<string, number> = {};
    for (const client of this.connectedClients.values()) {
      stats[client.platform] = (stats[client.platform] || 0) + 1;
    }
    return {
      total: this.connectedClients.size,
      byPlatform: stats,
    };
  }
}
