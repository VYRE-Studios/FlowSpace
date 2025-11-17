import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'presence/presence_service.dart';
import 'workspaces/workspace_activity_service.dart';
import '../ui/widgets/sidebar/right_sidebar.dart';

/// WebSocket client for P2P gateway.
/// 
/// This replaces the direct UDP P2P implementation in Flutter.
/// All P2P operations now go through the backend service via WebSocket.
class P2PGatewayClient {
  static final P2PGatewayClient instance = P2PGatewayClient._internal();

  P2PGatewayClient._internal();

  IO.Socket? _socket;
  bool _connected = false;
  final StreamController<Map<String, dynamic>> _events = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of P2P events from the gateway.
  Stream<Map<String, dynamic>> get events => _events.stream;

  /// Whether the client is connected to the gateway.
  bool get isConnected => _connected;

  /// Connect to the P2P gateway.
  Future<void> connect() async {
    if (_socket != null && _connected) {
      print('P2PGatewayClient: Already connected');
      return;
    }

    print('P2PGatewayClient: Connecting to P2P gateway...');

    // Try multiple ports in case backend auto-selected a different port
    final ports = [4000, 4001, 4002, 4003, 4004];
    bool connected = false;
    
    for (final port in ports) {
      try {
        _socket = IO.io(
          'http://localhost:$port',
          IO.OptionBuilder()
              .setTransports(['websocket'])
              .setPath('/p2p')
              .disableAutoConnect()
              .setTimeout(2000) // 2 second timeout
              .build(),
        );

        _socket!.onConnect((_) {
          _connected = true;
          connected = true;
          print('P2PGatewayClient: Connected to P2P gateway on port $port');
          
          // Request initial peer list
          requestPeers();
        });

        _socket!.onDisconnect((_) {
          _connected = false;
          print('P2PGatewayClient: Disconnected from P2P gateway');
        });

        _socket!.on('event', (data) {
          if (data is Map<String, dynamic>) {
            _handleEvent(data);
          }
        });

        _socket!.onError((error) {
          // Silently handle errors - backend might not be running
          _connected = false;
          if (port == ports.last) {
            // Only log if all ports failed
            print('P2PGatewayClient: Could not connect to any port');
          }
        });

        _socket!.connect();
        
        // Wait a bit to see if connection succeeds
        await Future.delayed(const Duration(milliseconds: 500));
        if (connected) {
          return; // Successfully connected
        } else {
          _socket?.dispose();
          _socket = null;
        }
      } catch (e) {
        // Try next port
        if (_socket != null) {
          _socket?.dispose();
          _socket = null;
        }
        if (port == ports.last) {
          print('P2PGatewayClient: Failed to connect to any port');
        }
      }
    }
  }

  /// Disconnect from the gateway.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _connected = false;
  }

  /// Send an encrypted message to a peer.
  void sendEncryptedMessage(String to, String ciphertext) {
    if (!_connected || _socket == null) {
      print('P2PGatewayClient: Not connected, cannot send message');
      return;
    }

    _socket!.emit('event', {
      'type': 'send_message',
      'to': to,
      'ciphertext': ciphertext,
    });
  }

  /// Request the current peer list.
  void requestPeers() {
    if (!_connected || _socket == null) return;

    _socket!.emit('event', {
      'type': 'request_peers',
    });
  }

  /// Request node identity.
  void requestIdentity() {
    if (!_connected || _socket == null) return;

    _socket!.emit('event', {
      'type': 'request_identity',
    });
  }

  /// Broadcast presence status.
  void broadcastPresence(String status) {
    if (!_connected || _socket == null) return;

    _socket!.emit('event', {
      'type': 'broadcast_presence',
      'status': status,
    });
  }

  /// Handle incoming events from the gateway.
  void _handleEvent(Map<String, dynamic> event) {
    final type = event['type'] as String?;
    if (type == null) return;

    switch (type) {
      case 'peer_discovered':
        _handlePeerDiscovered(event);
        break;
      case 'peer_lost':
        _handlePeerLost(event);
        break;
      case 'peer_update':
        _handlePeerUpdate(event);
        break;
      case 'message_received':
        _handleMessageReceived(event);
        break;
      case 'delivery_status':
        _handleDeliveryStatus(event);
        break;
      case 'p2p_status':
        _handleP2PStatus(event);
        break;
      default:
        print('P2PGatewayClient: Unknown event type: $type');
    }

    // Emit to stream
    _events.add(event);
  }

  void _handlePeerDiscovered(Map<String, dynamic> event) {
    final peerId = event['peerId'] as String?;
    if (peerId == null) return;

    // Update presence service
    PresenceService.instance.updatePeerStatus(peerId, PresenceStatus.online);

    // Add to activity feed
    WorkspaceActivityService.instance.addEvent(
      ActivityEvent(
        description: 'Peer discovered: ${peerId.substring(0, 8)}...',
        timestamp: DateTime.now(),
      ),
    );
  }

  void _handlePeerLost(Map<String, dynamic> event) {
    final peerId = event['peerId'] as String?;
    if (peerId == null) return;

    PresenceService.instance.updatePeerStatus(peerId, PresenceStatus.offline);

    WorkspaceActivityService.instance.addEvent(
      ActivityEvent(
        description: 'Peer disconnected: ${peerId.substring(0, 8)}...',
        timestamp: DateTime.now(),
      ),
    );
  }

  void _handlePeerUpdate(Map<String, dynamic> event) {
    final peerId = event['peerId'] as String?;
    final online = event['online'] as bool?;
    if (peerId == null || online == null) return;

    PresenceService.instance.updatePeerStatus(
      peerId,
      online ? PresenceStatus.online : PresenceStatus.offline,
    );
  }

  void _handleMessageReceived(Map<String, dynamic> event) {
    final from = event['from'] as String?;
    final ciphertext = event['ciphertext'] as String?;
    if (from == null || ciphertext == null) return;

    WorkspaceActivityService.instance.addEvent(
      ActivityEvent(
        description: 'Message received from ${from.substring(0, 8)}...',
        timestamp: DateTime.now(),
      ),
    );
  }

  void _handleDeliveryStatus(Map<String, dynamic> event) {
    final status = event['status'] as String?;
    final id = event['id'] as String?;
    print('P2PGatewayClient: Delivery status for $id: $status');
  }

  void _handleP2PStatus(Map<String, dynamic> event) {
    final nodeId = event['nodeId'] as String?;
    final online = event['online'] as bool?;
    final peerCount = event['peerCount'] as int?;
    final queueSize = event['queueSize'] as int?;
    print('P2PGatewayClient: Status - nodeId: $nodeId, online: $online, peers: $peerCount, queue: $queueSize');
  }
}

