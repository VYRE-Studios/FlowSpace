import { Injectable, Logger } from '@nestjs/common';
import { Server, Socket } from 'socket.io';

import { P2PRuntimeService } from '../p2p-runtime/p2p-runtime.service';
import {
  WSIncomingEvent,
  WSOutgoingEvent,
  WSIncomingSendMessage,
  WSIncomingRequestPeers,
  WSIncomingRequestIdentity,
  WSIncomingBroadcastPresence,
} from './p2p-events.types';

/**
 * Service that handles P2P gateway business logic.
 * Bridges between WebSocket clients and the P2P runtime.
 */
@Injectable()
export class P2PGatewayService {
  private readonly logger = new Logger(P2PGatewayService.name);
  private serverInstance?: Server;

  constructor(private readonly runtime: P2PRuntimeService) {
    // Subscribe to P2P runtime events and forward to WebSocket clients
    this.setupEventForwarding();
  }

  /**
   * Attach the WebSocket server instance for broadcasting.
   */
  attachServer(server: Server) {
    this.serverInstance = server;
  }

  /**
   * Broadcast an event to all connected WebSocket clients.
   */
  broadcast(payload: WSOutgoingEvent) {
    if (this.serverInstance) {
      this.serverInstance.emit('event', payload);
      this.logger.debug(`Broadcasted: ${payload.type}`);
    }
  }

  /**
   * Send status to a specific client.
   */
  async sendStatusToClient(client: Socket) {
    const status = await this.runtime.getStatus();
    client.emit('event', {
      type: 'p2p_status',
      nodeId: status.nodeId,
      online: status.online,
      peerCount: status.peerCount,
      queueSize: status.queueSize,
    } as WSOutgoingEvent);
  }

  /**
   * Handle incoming events from WebSocket clients.
   */
  async handleIncomingEvent(
    body: WSIncomingEvent,
    client: Socket,
  ): Promise<any> {
    switch (body.type) {
      case 'send_message': {
        const msg = body as WSIncomingSendMessage;
        const result = await this.runtime.sendMessage(msg.to, msg.ciphertext);
        return { success: true, status: result.status, id: result.id };
      }

      case 'request_peers': {
        const peers = await this.runtime.getPeerList();
        return { success: true, peers };
      }

      case 'request_identity': {
        const identity = await this.runtime.getIdentity();
        return { success: true, identity };
      }

      case 'broadcast_presence': {
        const presence = body as WSIncomingBroadcastPresence;
        await this.runtime.broadcastPresence(presence.status);
        return { success: true };
      }

      default:
        this.logger.warn(`Unknown event type: ${(body as any).type}`);
        return { success: false, error: 'Unknown event type' };
    }
  }

  /**
   * Set up event forwarding from P2P runtime to WebSocket clients.
   */
  private setupEventForwarding() {
    // Forward peer discovery events
    this.runtime.on('peer_discovered', (peer: any) => {
      this.broadcast({
        type: 'peer_discovered',
        peerId: peer.id,
        pubkey: peer.pubkey,
        lastSeen: peer.lastSeen,
        address: peer.address,
      });
    });

    // Forward peer lost events
    this.runtime.on('peer_lost', (peerId: string) => {
      this.broadcast({
        type: 'peer_lost',
        peerId,
      });
    });

    // Forward peer update events
    this.runtime.on('peer_update', (peer: any) => {
      this.broadcast({
        type: 'peer_update',
        peerId: peer.id,
        lastSeen: peer.lastSeen,
        online: peer.online,
      });
    });

    // Forward message received events
    this.runtime.on('message_received', (msg: any) => {
      this.broadcast({
        type: 'message_received',
        from: msg.from,
        ciphertext: msg.ciphertext,
        timestamp: msg.timestamp,
      });
    });

    // Forward delivery status events
    this.runtime.on('delivery_status', (status: any) => {
      this.broadcast({
        type: 'delivery_status',
        id: status.id,
        status: status.status,
        peerId: status.peerId,
      });
    });
  }
}

