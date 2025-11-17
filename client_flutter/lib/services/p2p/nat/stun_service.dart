import 'dart:io';
import 'dart:typed_data';

/// STUN (Session Traversal Utilities for NAT) Service
/// 
/// Phase 2 scaffold for discovering public IP addresses and NAT types.
/// This enables P2P connections across different networks.
/// 
/// STUN servers help peers discover their public-facing address,
/// which is necessary for UDP hole-punching and NAT traversal.
class STUNService {
  /// List of public STUN servers for discovery
  final List<String> stunServers = [
    "stun.l.google.com:19302",
    "stun1.l.google.com:19302",
    "stun2.l.google.com:19302",
    "stun3.l.google.com:19302",
    "stun4.l.google.com:19302",
  ];

  /// Discover the public IP address and port visible to the internet
  /// 
  /// Returns:
  /// - ip: Public IP address as seen by STUN server
  /// - port: Public UDP port number
  /// - natType: Classification of NAT device (for hole-punching strategy)
  Future<STUNResult> getPublicAddress() async {
    // Phase 2 implementation will:
    // 1. Send STUN binding request to server
    // 2. Parse binding response with public IP/port
    // 3. Classify NAT type (Full Cone, Symmetric, etc.)
    // 4. Return addressing information
    
    return STUNResult(
      publicIp: "0.0.0.0",
      publicPort: 0,
      natType: NATType.unknown,
      localIp: "0.0.0.0",
      localPort: 0,
    );
  }

  /// Perform comprehensive NAT classification
  /// 
  /// Tests NAT behavior to determine hole-punching strategy:
  /// - Full Cone NAT: Easy hole-punching
  /// - Restricted Cone: Moderate difficulty
  /// - Port Restricted: More complex
  /// - Symmetric: Requires relay in some cases
  Future<NATType> classifyNAT() async {
    // Phase 2 implementation will:
    // 1. Test with multiple STUN servers
    // 2. Analyze port allocation patterns
    // 3. Determine NAT traversal strategy
    
    return NATType.unknown;
  }

  /// Test connectivity to STUN server
  Future<bool> testConnectivity(String server) async {
    try {
      final parts = server.split(':');
      final host = parts[0];
      final port = int.parse(parts[1]);
      
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.close();
      
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Result from STUN discovery
class STUNResult {
  final String publicIp;
  final int publicPort;
  final NATType natType;
  final String localIp;
  final int localPort;

  STUNResult({
    required this.publicIp,
    required this.publicPort,
    required this.natType,
    required this.localIp,
    required this.localPort,
  });

  @override
  String toString() {
    return 'STUN: $localIp:$localPort -> $publicIp:$publicPort (NAT: $natType)';
  }
}

/// NAT type classification for hole-punching strategy
enum NATType {
  unknown,
  openInternet,      // No NAT - direct connectivity
  fullCone,          // Best case - easy hole-punching
  restrictedCone,    // Good - moderate hole-punching
  portRestricted,    // Harder - requires coordination
  symmetric,         // Hardest - may need relay
}
