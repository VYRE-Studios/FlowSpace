import 'package:flutter/material.dart';
import '../../services/notification_service.dart';

/// Displays a badge with the current unread notification count
class NotificationBadgeWidget extends StatelessWidget {
  final int? count;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;

  const NotificationBadgeWidget({
    super.key,
    this.count,
    this.size = 20,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final badgeCount = count ?? NotificationService.instance.badgeCount;

    if (badgeCount == 0) {
      return const SizedBox.shrink();
    }

    final displayCount = badgeCount > 99 ? '99+' : badgeCount.toString();
    final bgColor = backgroundColor ?? Theme.of(context).colorScheme.error;
    final fgColor = textColor ?? Theme.of(context).colorScheme.onError;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(size / 2),
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          displayCount,
          style: TextStyle(
            color: fgColor,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// Wraps a child with a notification badge in the top-right corner
class BadgedWidget extends StatelessWidget {
  final Widget child;
  final int? badgeCount;
  final bool showZero;

  const BadgedWidget({
    super.key,
    required this.child,
    this.badgeCount,
    this.showZero = false,
  });

  @override
  Widget build(BuildContext context) {
    final count = badgeCount ?? NotificationService.instance.badgeCount;

    if (!showZero && count == 0) {
      return child;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -8,
          right: -8,
          child: NotificationBadgeWidget(count: count),
        ),
      ],
    );
  }
}

/// Animated notification badge that pulses when count increases
class AnimatedNotificationBadge extends StatefulWidget {
  final int count;
  final double size;

  const AnimatedNotificationBadge({
    super.key,
    required this.count,
    this.size = 20,
  });

  @override
  State<AnimatedNotificationBadge> createState() =>
      _AnimatedNotificationBadgeState();
}

class _AnimatedNotificationBadgeState extends State<AnimatedNotificationBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _previousCount = widget.count;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(AnimatedNotificationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.count > _previousCount) {
      _controller.forward(from: 0.0);
    }
    _previousCount = widget.count;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.count == 0) {
      return const SizedBox.shrink();
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: NotificationBadgeWidget(
        count: widget.count,
        size: widget.size,
      ),
    );
  }
}
