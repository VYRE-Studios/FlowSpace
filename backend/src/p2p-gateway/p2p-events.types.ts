/**
 * WebSocket event type definitions for P2P gateway.
 * These define the contract between the Flutter UI and the backend P2P service.
 */

// Outgoing events (backend → UI)
export interface WSOutgoingPeerDiscovered {
  type: 'peer_discovered';
  peerId: string;
  pubkey: string;
  lastSeen: number;
  address?: string;
}

export interface WSOutgoingPeerLost {
  type: 'peer_lost';
  peerId: string;
}

export interface WSOutgoingPeerUpdate {
  type: 'peer_update';
  peerId: string;
  lastSeen: number;
  online: boolean;
}

export interface WSOutgoingMessageReceived {
  type: 'message_received';
  from: string;
  ciphertext: string;
  timestamp: number;
}

export interface WSOutgoingDeliveryStatus {
  type: 'delivery_status';
  id: string;
  status: 'queued' | 'sent' | 'delivered' | 'failed';
  peerId?: string;
}

export interface WSOutgoingP2PStatus {
  type: 'p2p_status';
  nodeId: string;
  online: boolean;
  peerCount: number;
  queueSize: number;
}

// Incoming events (UI → backend)
export interface WSIncomingSendMessage {
  type: 'send_message';
  to: string;
  ciphertext: string;
}

export interface WSIncomingBroadcastPresence {
  type: 'broadcast_presence';
  status: 'online' | 'away' | 'busy' | 'offline';
}

export interface WSIncomingRequestPeers {
  type: 'request_peers';
}

export interface WSIncomingRequestIdentity {
  type: 'request_identity';
}

export type WSOutgoingEvent =
  | WSOutgoingPeerDiscovered
  | WSOutgoingPeerLost
  | WSOutgoingPeerUpdate
  | WSOutgoingMessageReceived
  | WSOutgoingDeliveryStatus
  | WSOutgoingP2PStatus;

export type WSIncomingEvent =
  | WSIncomingSendMessage
  | WSIncomingBroadcastPresence
  | WSIncomingRequestPeers
  | WSIncomingRequestIdentity;

