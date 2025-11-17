import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class UdpSocketService {
  RawDatagramSocket? socket;
  final int port = 33445;

  Future<void> initialize() async {
    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    socket?.broadcastEnabled = true;  // Enable UDP broadcast
    _listen();
  }

  void _listen() {
    socket?.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = socket?.receive();
        if (datagram == null) return;
        
        final data = datagram.data;
        final address = datagram.address.address;
        onPacketReceived?.call(data, address);
      }
    });
  }

  Function(Uint8List data, String address)? onPacketReceived;

  Future<void> sendPacket(Uint8List data, String address) async {
    if (socket == null) return;
    
    final destination = InternetAddress(address);
    socket?.send(data, destination, port);
  }

  Future<void> broadcastPacket(Uint8List data) async {
    if (socket == null) return;
    
    // Broadcast to local subnet
    final broadcast = InternetAddress('255.255.255.255');
    socket?.send(data, broadcast, port);
  }

  void dispose() {
    socket?.close();
    socket = null;
  }
}
