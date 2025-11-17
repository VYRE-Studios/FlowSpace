import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { EventEmitter } from 'events';
import * as dgram from 'dgram';
import { PrismaService } from '../database/prisma.service';

/**
 * P2P Runtime Service
 * 
 * Handles all UDP networking, peer discovery, encryption, and message delivery.
 * This is the core P2P engine that runs in the background service.
 */
@Injectable()
export class P2PRuntimeService extends EventEmitter implements OnModuleInit {
  private readonly logger = new Logger(P2PRuntimeService.name);
  private socket?: dgram.Socket;
  private nodeId: string = '';
  private publicKey: string = '';
  private privateKey: string = '';
  private readonly PORT = 33445;
  private readonly DISCOVERY_INTERVAL = 2000; // 2 seconds
  private discoveryTimer?: NodeJS.Timeout;
  private retryTimer?: NodeJS.Timeout;
  private peers: Map<string, { id: string; pubkey: string; address: string; lastSeen: Date }> = new Map();

  constructor(private readonly prisma: PrismaService) {
    super();
  }

  async onModuleInit() {
    this.logger.log('Initializing P2P Runtime...');
    await this.initialize();
  }

  /**
   * Initialize the P2P runtime.
   */
  async initialize() {
    // Generate or load node identity
    await this.loadOrCreateIdentity();

    // Initialize UDP socket
    this.socket = dgram.createSocket('udp4');
    
    this.socket.on('message', (msg, rinfo) => {
      this.handlePacket(msg, rinfo);
    });

    this.socket.on('error', (err) => {
      this.logger.error(`UDP socket error: ${err.message}`);
    });

    await new Promise<void>((resolve, reject) => {
      this.socket!.bind(this.PORT, '0.0.0.0', () => {
        // Enable broadcast
        this.socket!.setBroadcast(true);
        this.logger.log(`P2P Runtime listening on UDP port ${this.PORT}`);
        resolve();
      });
      
      this.socket!.on('error', (err: NodeJS.ErrnoException) => {
        if (err.code === 'EADDRINUSE') {
          this.logger.warn(`Port ${this.PORT} already in use, P2P Runtime will run in limited mode`);
          // Port in use - likely another instance running, continue without UDP
          this.socket = undefined;
          resolve();
        } else {
          this.logger.error(`UDP socket error: ${err.message}`);
          reject(err);
        }
      });
    });

    // Start discovery loop
    this.startDiscovery();

    // Start retry loop for queued messages
    this.startRetryLoop();

    // Load persisted peers
    await this.loadPeers();

    this.logger.log('P2P Runtime initialized');
  }

  /**
   * Load or create node identity (public/private key pair).
   */
  private async loadOrCreateIdentity() {
    // For now, generate a simple ID. In production, use proper crypto.
    this.nodeId = `node_${Date.now()}_${Math.random().toString(36).substring(7)}`;
    this.publicKey = Buffer.from(this.nodeId).toString('base64');
    this.privateKey = `priv_${this.publicKey}`;
    this.logger.log(`Node ID: ${this.nodeId}`);
  }

  /**
   * Start the discovery broadcast loop.
   */
  private startDiscovery() {
    this.discoveryTimer = setInterval(() => {
      this.broadcastDiscovery();
    }, this.DISCOVERY_INTERVAL);
  }

  /**
   * Broadcast discovery packet to LAN.
   */
  private broadcastDiscovery() {
    if (!this.socket) {
      // Socket not available (port in use), skip discovery
      return;
    }

    const packet = Buffer.from(JSON.stringify({
      type: 'discovery',
      nodeId: this.nodeId,
      pubkey: this.publicKey,
      timestamp: Date.now(),
    }));

    // Broadcast to LAN (255.255.255.255)
    this.socket.send(packet, this.PORT, '255.255.255.255', (err) => {
      if (err) {
        this.logger.debug(`Discovery broadcast error: ${err.message}`);
      }
    });
  }

  /**
   * Handle incoming UDP packet.
   */
  private async handlePacket(msg: Buffer, rinfo: dgram.RemoteInfo) {
    try {
      const data = JSON.parse(msg.toString());
      
      if (data.type === 'discovery') {
        await this.handleDiscovery(data, rinfo);
      } else if (data.type === 'message') {
        await this.handleMessage(data, rinfo);
      }
    } catch (err) {
      this.logger.debug(`Failed to parse packet: ${err}`);
    }
  }

  /**
   * Handle peer discovery packet.
   */
  private async handleDiscovery(data: any, rinfo: dgram.RemoteInfo) {
    const peerId = data.nodeId;
    const pubkey = data.pubkey;
    const address = `${rinfo.address}:${rinfo.port}`;

    // Don't process our own discovery packets
    if (peerId === this.nodeId) return;

    const now = new Date();
    const existing = this.peers.get(peerId);

    if (!existing) {
      // New peer discovered
      this.peers.set(peerId, { id: peerId, pubkey, address, lastSeen: now });
      
      // Persist to database
      await this.prisma.peer.upsert({
        where: { id: peerId },
        update: { lastSeen: now, address },
        create: {
          id: peerId,
          pubkey,
          address,
          lastSeen: now,
        },
      });

      // Emit event for gateway
      this.emit('peer_discovered', { id: peerId, pubkey, lastSeen: now.getTime(), address });
      this.logger.log(`Peer discovered: ${peerId} at ${address}`);
    } else {
      // Update last seen
      existing.lastSeen = now;
      await this.prisma.peer.update({
        where: { id: peerId },
        data: { lastSeen: now, address },
      });

      this.emit('peer_update', { id: peerId, lastSeen: now.getTime(), online: true });
    }
  }

  /**
   * Handle incoming message packet.
   */
  private async handleMessage(data: any, rinfo: dgram.RemoteInfo) {
    const fromPeer = data.from;
    const ciphertext = data.ciphertext;

    // Store in incoming queue
    await this.prisma.incomingMessage.create({
      data: {
        fromPeer,
        ciphertext,
        timestamp: new Date(),
        processed: false,
      },
    });

    // Emit to gateway
    this.emit('message_received', {
      from: fromPeer,
      ciphertext,
      timestamp: Date.now(),
    });

    // Mark as processed
    await this.prisma.incomingMessage.updateMany({
      where: { fromPeer, processed: false },
      data: { processed: true },
    });

    this.logger.debug(`Message received from ${fromPeer}`);
  }

  /**
   * Send a message to a peer.
   */
  async sendMessage(peerId: string, ciphertext: string): Promise<{ status: string; id?: string }> {
    const peer = this.peers.get(peerId);
    
    if (!peer) {
      // Peer not online, queue message
      const queued = await this.prisma.outgoingMessage.create({
        data: {
          toPeer: peerId,
          ciphertext,
          timestamp: new Date(),
          delivered: false,
          retryCount: 0,
        },
      });

      this.emit('delivery_status', {
        id: queued.id,
        status: 'queued',
        peerId,
      });

      return { status: 'queued', id: queued.id };
    }

    // Try to send immediately
    const success = await this.trySendUDP(peer.address, peerId, ciphertext);

    if (success) {
      this.emit('delivery_status', {
        id: `msg_${Date.now()}`,
        status: 'sent',
        peerId,
      });
      return { status: 'sent' };
    } else {
      // Failed, queue it
      const queued = await this.prisma.outgoingMessage.create({
        data: {
          toPeer: peerId,
          ciphertext,
          timestamp: new Date(),
          delivered: false,
          retryCount: 0,
        },
      });

      return { status: 'queued', id: queued.id };
    }
  }

  /**
   * Try to send a UDP message.
   */
  private async trySendUDP(address: string, peerId: string, ciphertext: string): Promise<boolean> {
    return new Promise((resolve) => {
      if (!this.socket) {
        resolve(false);
        return;
      }

      const [host, port] = address.split(':');
      const packet = Buffer.from(JSON.stringify({
        type: 'message',
        from: this.nodeId,
        to: peerId,
        ciphertext,
        timestamp: Date.now(),
      }));

      this.socket!.send(packet, parseInt(port || '33445'), host, (err) => {
        resolve(!err);
      });
    });
  }

  /**
   * Start retry loop for queued messages.
   */
  private startRetryLoop() {
    this.retryTimer = setInterval(async () => {
      await this.processRetryQueue();
    }, 3000); // Check every 3 seconds
  }

  /**
   * Process queued messages and retry delivery.
   */
  private async processRetryQueue() {
    const messages = await this.prisma.outgoingMessage.findMany({
      where: { delivered: false },
      take: 10, // Process 10 at a time
    });

    for (const msg of messages) {
      const peer = this.peers.get(msg.toPeer);
      
      if (!peer) {
        // Peer still not online, check if we should retry
        const shouldRetry = this.shouldRetry(msg.retryCount, msg.timestamp);
        if (!shouldRetry) continue;

        // Update retry count
        await this.prisma.outgoingMessage.update({
          where: { id: msg.id },
          data: { retryCount: msg.retryCount + 1 },
        });
        continue;
      }

      // Peer is online, try to send
      const success = await this.trySendUDP(peer.address, msg.toPeer, msg.ciphertext);

      if (success) {
        await this.prisma.outgoingMessage.update({
          where: { id: msg.id },
          data: { delivered: true },
        });

        this.emit('delivery_status', {
          id: msg.id,
          status: 'delivered',
          peerId: msg.toPeer,
        });
      } else {
        // Still failed, increment retry
        await this.prisma.outgoingMessage.update({
          where: { id: msg.id },
          data: { retryCount: msg.retryCount + 1 },
        });
      }
    }
  }

  /**
   * Determine if a message should be retried based on exponential backoff.
   */
  private shouldRetry(retryCount: number, timestamp: Date): boolean {
    const now = Date.now();
    const elapsed = now - timestamp.getTime();
    
    // Exponential backoff: immediate, 1s, 5s, 15s, 30s, then every 60s
    const delays = [0, 1000, 5000, 15000, 30000];
    const delay = retryCount < delays.length 
      ? delays[retryCount] 
      : 60000 * Math.pow(2, retryCount - delays.length);
    
    return elapsed >= delay;
  }

  /**
   * Get list of known peers.
   */
  async getPeerList() {
    const peers = await this.prisma.peer.findMany({
      orderBy: { lastSeen: 'desc' },
      take: 100,
    });

    return peers.map(p => ({
      id: p.id,
      pubkey: p.pubkey,
      lastSeen: p.lastSeen.getTime(),
      address: p.address,
      online: this.peers.has(p.id),
    }));
  }

  /**
   * Get node identity.
   */
  async getIdentity() {
    return {
      nodeId: this.nodeId,
      publicKey: this.publicKey,
    };
  }

  /**
   * Get runtime status.
   */
  async getStatus() {
    const queueSize = await this.prisma.outgoingMessage.count({
      where: { delivered: false },
    });

    return {
      nodeId: this.nodeId,
      online: !!this.socket,
      peerCount: this.peers.size,
      queueSize,
      udpPort: this.socket ? this.PORT : null,
      warning: !this.socket ? 'UDP port in use, running in limited mode' : undefined,
    };
  }

  /**
   * Broadcast presence status.
   */
  async broadcastPresence(status: string) {
    // Presence is handled through discovery packets
    // This can be extended to include status in discovery
    this.logger.debug(`Broadcasting presence: ${status}`);
  }

  /**
   * Load persisted peers from database.
   */
  private async loadPeers() {
    const peers = await this.prisma.peer.findMany({
      where: {
        lastSeen: {
          gte: new Date(Date.now() - 60000), // Last minute
        },
      },
    });

    for (const peer of peers) {
      if (peer.address) {
        this.peers.set(peer.id, {
          id: peer.id,
          pubkey: peer.pubkey,
          address: peer.address,
          lastSeen: peer.lastSeen,
        });
      }
    }

    this.logger.log(`Loaded ${peers.length} persisted peers`);
  }

  /**
   * Cleanup on module destroy.
   */
  onModuleDestroy() {
    if (this.discoveryTimer) {
      clearInterval(this.discoveryTimer);
    }
    if (this.retryTimer) {
      clearInterval(this.retryTimer);
    }
    if (this.socket) {
      this.socket.close();
    }
  }
}

