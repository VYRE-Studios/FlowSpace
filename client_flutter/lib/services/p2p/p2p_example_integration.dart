import 'package:flutter/material.dart';
import 'p2p_router_service.dart';

/// Example integration showing how to use P2P messaging in FLO
/// 
/// This demonstrates:
/// - Initializing the P2P system
/// - Discovering peers on LAN
/// - Connecting to peers
/// - Sending and receiving messages
/// 
/// Usage:
/// ```dart
/// final p2pChat = P2PChatExample();
/// await p2pChat.initialize();
/// ```
class P2PChatExample {
  final P2PRouterService router = P2PRouterService();

  Future<void> initialize() async {
    // Initialize the P2P router
    await router.initialize();

    // Set up callbacks for peer discovery
    router.onPeerDiscovered = (peerId, address) {
      debugPrint('🔵 New peer found: $peerId at $address');
      // You can auto-connect here or show in UI
      // For now, let's auto-connect to discovered peers
      _autoConnectToPeer(peerId, address);
    };

    // Set up callbacks for connection establishment
    router.onConnectionEstablished = (peerId, address) {
      debugPrint('✅ Connected to peer: $peerId');
      // Now you can send messages to this peer
    };

    // Set up callbacks for incoming messages
    router.onMessageReceived = (message) {
      debugPrint('📨 Received message: $message');
      // Forward to chat UI or store in database
      _handleIncomingMessage(message);
    };

    debugPrint('🚀 P2P Chat initialized and discovering peers...');
  }

  Future<void> _autoConnectToPeer(String peerId, String address) async {
    // Wait a moment to ensure handshake completes
    await Future.delayed(Duration(milliseconds: 100));
    await router.connectToPeer(peerId, address);
  }

  void _handleIncomingMessage(String message) {
    // TODO: Store in SQLite database
    // TODO: Update chat UI
    // For now, just print
    debugPrint('Message ready for UI: $message');
  }

  Future<void> sendMessageToPeer(String peerId, String text) async {
    await router.sendMessage(text, peerId);
    debugPrint('📤 Sent message to $peerId: $text');
  }

  List<String> getActivePeers() {
    return router.getActivePeers();
  }

  List<String> getDiscoveredPeers() {
    return router.getDiscoveredPeers();
  }

  void dispose() {
    router.dispose();
  }
}

/// Example Flutter widget showing P2P chat UI
class P2PChatWidget extends StatefulWidget {
  const P2PChatWidget({super.key});

  @override
  State<P2PChatWidget> createState() => _P2PChatWidgetState();
}

class _P2PChatWidgetState extends State<P2PChatWidget> {
  final P2PChatExample p2pChat = P2PChatExample();
  final TextEditingController messageController = TextEditingController();
  List<String> messages = [];
  List<String> peers = [];
  String? selectedPeer;

  @override
  void initState() {
    super.initState();
    _initializeP2P();
  }

  Future<void> _initializeP2P() async {
    await p2pChat.initialize();

    // Set up message receiver
    p2pChat.router.onMessageReceived = (message) {
      setState(() {
        messages.add('Peer: $message');
      });
    };

    // Set up peer discovery
    p2pChat.router.onConnectionEstablished = (peerId, address) {
      setState(() {
        peers = p2pChat.getActivePeers();
        selectedPeer ??= peerId; // Select first peer automatically
      });
    };
  }

  void _sendMessage() {
    if (selectedPeer == null || messageController.text.isEmpty) return;

    final text = messageController.text;
    p2pChat.sendMessageToPeer(selectedPeer!, text);

    setState(() {
      messages.add('You: $text');
    });

    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('P2P Chat'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                '${peers.length} peers',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Peer selector
          if (peers.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8.0),
              color: Colors.blue.shade100,
              child: Row(
                children: [
                  const Text('Chat with: '),
                  Expanded(
                    child: DropdownButton<String>(
                      value: selectedPeer,
                      isExpanded: true,
                      items: peers.map((peer) {
                        return DropdownMenuItem(
                          value: peer,
                          child: Text(peer.substring(0, 16) + '...'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedPeer = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Message list
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(messages[index]),
                );
              },
            ),
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    p2pChat.dispose();
    messageController.dispose();
    super.dispose();
  }
}
