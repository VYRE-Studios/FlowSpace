import 'package:flutter/material.dart';

class ToastService {
  static final ToastService instance = ToastService._();
  ToastService._();

  GlobalKey<NavigatorState>? _navigatorKey;
  OverlayEntry? _currentOverlay;

  void init(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
  }

  void showUserJoined(String displayName) {
    _showToast(
      icon: Icons.person_add,
      iconColor: Colors.green,
      message: '$displayName joined',
    );
  }

  void showUserLeft(String displayName) {
    _showToast(
      icon: Icons.person_remove,
      iconColor: Colors.orange,
      message: '$displayName left',
    );
  }

  void showSuccess(String message) {
    _showToast(
      icon: Icons.check_circle,
      iconColor: Colors.green,
      message: message,
    );
  }

  void showError(String message) {
    _showToast(
      icon: Icons.error,
      iconColor: Colors.red,
      message: message,
    );
  }

  void showInfo(String message) {
    _showToast(
      icon: Icons.info,
      iconColor: Colors.blue,
      message: message,
    );
  }

  void _showToast({
    required IconData icon,
    required Color iconColor,
    required String message,
  }) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    // Remove previous toast
    _currentOverlay?.remove();
    _currentOverlay = null;

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 80,
        left: 0,
        right: 0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: iconColor.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: iconColor, size: 20),
                    const SizedBox(width: 12),
                    Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    _currentOverlay = overlayEntry;
    overlay.insert(overlayEntry);

    // Auto-remove after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
      if (_currentOverlay == overlayEntry) {
        _currentOverlay = null;
      }
    });
  }
}
