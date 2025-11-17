# FLO P2P Messaging System Design
## Reverse-Engineered from ToxCore Architecture

**License:** MIT  
**Purpose:** Serverless peer-to-peer encrypted messaging for FLO  
**Status:** Design Phase

---

## Overview

Based on ToxCore's architecture, we will build a simplified P2P messaging system that enables direct communication between FLO clients without requiring a central server.

## Core Components

### 1. **DHT (Distributed Hash Table)**
**Purpose:** Peer discovery and routing

**How it works:**
- Each peer has a unique 256-bit public key ID
- Peers maintain a routing table of other known peers
- Uses Kademlia-style XOR distance metric for routing
- Bootstraps by connecting to known "bootstrap nodes" (can be any FLO client)

**Implementation:**
```dart
// lib/services/p2p/dht_service.dart
class DHTNode {
  final String publicKey;  // 32-byte ed25519 public key
  final String ipAddress;
  final int port;
  final DateTime lastSeen;
}

class DHTService {
  final Map<String, DHTNode> routingTable = {};
  
  Future<DHTNode?> findPeer(String publicKey) async {
    // XOR distance search
    // Query closest known peers
    // Return peer info or null
  }
  
  void addPeer(DHTNode node) {
    // Add to routing table
    // Maintain k-bucket structure
  }
}
```

### 2. **Key Exchange & Encryption**
**Purpose:** Establish encrypted sessions between peers

**Crypto Stack:**
- **Identity Keys:** Ed25519 (signing)
- **Encryption Keys:** X25519 (ECDH key exchange)
- **Symmetric Encryption:** XSalsa20 + Poly1305 (NaCl)
- **Random:** crypto.getRandomValues()

**Handshake Protocol:**
```
Alice → Bob: Cookie Request
Bob → Alice: Cookie Response (encrypted cookie)
Alice → Bob: Handshake (cookie + temp keypair + nonce)
Bob → Alice: Handshake Response (temp keypair)
Both: Derive shared secret using ECDH(temp_private, other_temp_public)
```

**Implementation:**
```dart
// lib/services/p2p/crypto_service.dart
class P2PCrypto {
  // Generate long-term identity keypair
  KeyPair generateIdentityKeys();
  
  // Generate ephemeral session keypair
  KeyPair generateSessionKeys();
  
  // ECDH key agreement
  Uint8List deriveSharedSecret(
    Uint8List privateKey,
    Uint8List publicKey
  );
  
  // Encrypt/decrypt messages
  Uint8List encrypt(Uint8List message, Uint8List key, Uint8List nonce);
  Uint8List decrypt(Uint8List ciphertext, Uint8List key, Uint8List nonce);
}
```

### 3. **Connection Management**
**Purpose:** Maintain connections with UDP hole-punching and TCP fallback

**Connection Types:**
- **Direct UDP:** Fastest, works on LAN and with port forwarding
- **UDP Hole-Punching:** Works behind most NATs
- **TCP Relay:** Fallback for strict NATs (uses other FLO peers as relays)

**Implementation:**
```dart
// lib/services/p2p/connection_service.dart
class P2PConnection {
  ConnectionType type; // udp_direct, udp_hole_punch, tcp_relay
  Socket? socket;
  Uint8List sessionKey;
  int nonce = 0;
  
  Future<void> sendMessage(Uint8List data) async {
    // Encrypt with session key and nonce
    // Send packet
    // Increment nonce
  }
  
  Stream<Uint8List> receiveMessages();
}

class ConnectionManager {
  Future<P2PConnection> connectToPeer(String publicKey) async {
    // 1. Lookup peer in DHT
    // 2. Try direct UDP connection
    // 3. Try UDP hole-punching
    // 4. Fall back to TCP relay
    // 5. Perform cryptographic handshake
    // 6. Return established connection
  }
}
```

### 4. **Packet Format**
**Purpose:** Standardized packet structure

**Packet Types:**
```
0x00: Ping Request
0x01: Ping Response
0x18: Cookie Request (24)
0x19: Cookie Response (25)
0x1A: Handshake (26)
0x1B: Data Packet (27)
0x20: DHT Announce
0x21: DHT Nodes Request
0x22: DHT Nodes Response
```

**Data Packet Structure:**
```
[1 byte: packet_type = 0x1B]
[2 bytes: nonce_suffix (last 2 bytes of nonce)]
[encrypted payload using session key + full nonce]

Decrypted payload:
[4 bytes: highest_received_packet_num + 1]
[4 bytes: current_packet_num]
[variable: actual message data]
```

### 5. **Reliable Delivery**
**Purpose:** Lossless messaging over lossy UDP

**How it works:**
- Each packet has a sequence number
- Receiver tracks which packets received
- Receiver sends packet request for missing packets
- Sender retransmits on request
- 10-second timeout for retransmission

**Implementation:**
```dart
// lib/services/p2p/reliable_service.dart
class ReliableTransport {
  Map<int, Uint8List> sendBuffer = {}; // Unacknowledged packets
  Map<int, Uint8List> recvBuffer = {}; // Out-of-order packets
  int sendSeqNum = 0;
  int recvSeqNum = 0;
  
  void sendReliable(Uint8List message) {
    sendBuffer[sendSeqNum] = message;
    connection.send(createPacket(sendSeqNum, message));
    sendSeqNum++;
  }
  
  void handlePacket(int seqNum, Uint8List data) {
    if (seqNum == recvSeqNum) {
      // In-order, deliver immediately
      deliverToApp(data);
      recvSeqNum++;
      // Check if buffered packets can now be delivered
      deliverBufferedPackets();
    } else if (seqNum > recvSeqNum) {
      // Out of order, buffer it
      recvBuffer[seqNum] = data;
      // Request missing packets
      requestMissingPackets();
    }
  }
}
```

---

## Implementation Plan

### Phase 1: Local Network P2P (Week 1)
**Goal:** Desktop and laptop can discover and message each other on same WiFi

1. **Basic UDP sockets** - Send/receive raw UDP packets
2. **Broadcast discovery** - Announce presence on LAN via broadcast
3. **Simple handshake** - Exchange public keys, derive shared secret
4. **Encrypted messaging** - Send encrypted text messages
5. **Flutter integration** - Replace chat_core.dart with P2P service

### Phase 2: NAT Traversal (Week 2)
**Goal:** Work across different networks using UDP hole-punching

1. **STUN client** - Discover public IP and port
2. **Hole-punching** - Simultaneous UDP to establish connection
3. **DHT basics** - Simple peer discovery system
4. **Bootstrap nodes** - Public FLO peers for initial connection

### Phase 3: TCP Relay Fallback (Week 3)
**Goal:** Work even behind strict NATs/firewalls

1. **Relay protocol** - Forward packets through helper peers
2. **Relay discovery** - Find willing relay nodes via DHT
3. **Multi-relay** - Use multiple relays for redundancy
4. **Seamless switching** - Auto-switch between UDP/TCP

### Phase 4: Production Hardening (Week 4)
**Goal:** Stable, secure, performant

1. **Reliable delivery** - Packet loss handling
2. **Connection recovery** - Reconnect after network changes
3. **Bandwidth optimization** - Compression, rate limiting
4. **Security audit** - Review crypto implementation
5. **Testing** - Cross-platform testing

---

## Key Differences from ToxCore

**Simplified:**
- No friend requests system (use existing FLO team membership)
- No file transfer (use existing vault)
- No audio/video (use existing Jitsi)
- No groups (use existing channels)

**FLO-Specific:**
- Integrate with SQLite for message persistence
- Use existing FLO encryption keys where possible
- Workspace-aware routing
- Team-based DHT segments

---

## Dependencies

**Dart Packages:**
```yaml
dependencies:
  cryptography: ^2.7.0          # Ed25519, X25519, XSalsa20-Poly1305
  pointycastle: ^3.7.0          # Additional crypto primitives
  udp: ^5.0.3                   # UDP sockets
  network_info_plus: ^5.0.0     # Network interface info
```

**No GPL code will be used** - All implementations will be clean-room from documentation/protocol specs.

---

## Timeline

**Total:** 4-6 weeks for production-ready P2P system

**Immediate (This week):**
- Implement basic UDP broadcast discovery
- Simple XSalsa20 encryption
- Message exchange on LAN

**This gets you chatting between desktop/laptop with NO server!**

---

## Testing Strategy

1. **LAN Test:** Two FLO instances on same network
2. **NAT Test:** Desktop at home, laptop on mobile hotspot  
3. **Relay Test:** Both behind strict NATs
4. **Reliability Test:** Simulate 10% packet loss
5. **Security Test:** Verify encryption, prevent replay attacks

---

## Next Steps

1. Create `lib/services/p2p/` directory structure
2. Implement `LanDiscoveryService` for local network
3. Implement `P2PCryptoService` using cryptography package
4. Create simple UDP socket wrapper
5. Build proof-of-concept: Two FLO instances exchanging encrypted messages on LAN

**Start with Phase 1 - LAN messaging only. This gives you working P2P in ~1 week.**

---

**This design is MIT-licensed and implements the protocol, not the code!**
