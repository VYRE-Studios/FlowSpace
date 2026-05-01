import 'package:flutter/material.dart';

class NetworkStatusBanner extends StatelessWidget {
  final bool isOnline;
  final bool isReconnecting;

  const NetworkStatusBanner({
    Key? key,
    required this.isOnline,
    this.isReconnecting = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isOnline && !isReconnecting) {
      return const SizedBox.shrink();
    }

    Color backgroundColor;
    IconData icon;
    String text;

    if (isReconnecting) {
      backgroundColor = Colors.orange;
      icon = Icons.sync;
      text = 'Reconnecting...';
    } else {
      backgroundColor = Colors.red;
      icon = Icons.wifi_off;
      text = 'No internet connection';
    }

    return Material(
      color: backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (isReconnecting) ...[
                const Spacer(),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
