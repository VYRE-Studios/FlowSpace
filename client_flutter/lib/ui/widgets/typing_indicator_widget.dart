import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/typing_indicator_provider.dart';

class TypingIndicatorWidget extends StatelessWidget {
  final String channelId;
  final TextStyle? textStyle;
  final EdgeInsets? padding;
  final Color? dotColor;
  final bool showDots;

  const TypingIndicatorWidget({
    Key? key,
    required this.channelId,
    this.textStyle,
    this.padding,
    this.dotColor,
    this.showDots = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TypingIndicatorProvider>(
      builder: (context, provider, _) {
        if (!provider.isAnyoneTyping(channelId)) {
          return const SizedBox.shrink();
        }

        final typingText = provider.getTypingText(channelId);

        return Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              if (showDots) ...[
                _TypingDots(color: dotColor ?? Theme.of(context).primaryColor),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  typingText,
                  style: textStyle ??
                      TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Animated typing dots indicator
class _TypingDots extends StatefulWidget {
  final Color color;

  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            const SizedBox(width: 3),
            _buildDot(1),
            const SizedBox(width: 3),
            _buildDot(2),
          ],
        );
      },
    );
  }

  Widget _buildDot(int index) {
    final delay = index * 0.2;
    final opacity = _calculateOpacity(delay);

    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color.withOpacity(opacity),
      ),
    );
  }

  double _calculateOpacity(double delay) {
    final progress = (_controller.value + delay) % 1.0;
    // Sine wave for smooth pulsing
    return 0.3 + (0.7 * (1 + Math.sin(progress * 2 * Math.pi)) / 2);
  }
}

/// Compact typing indicator for message list headers
class CompactTypingIndicator extends StatelessWidget {
  final String channelId;
  final int maxAvatars;

  const CompactTypingIndicator({
    Key? key,
    required this.channelId,
    this.maxAvatars = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<TypingIndicatorProvider>(
      builder: (context, provider, _) {
        final typingUsers = provider.getTypingUsers(channelId);

        if (typingUsers.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User avatars (if available)
              ...typingUsers.take(maxAvatars).map((user) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.grey[300],
                      child: Text(
                        (user.displayName ?? 'U')[0].toUpperCase(),
                        style: const TextStyle(fontSize: 8),
                      ),
                    ),
                  )),
              const SizedBox(width: 4),
              _TypingDots(color: Colors.grey[600]!),
            ],
          ),
        );
      },
    );
  }
}

// Math helper for sine calculation
class Math {
  static double sin(double value) {
    return value.sin();
  }

  static const double pi = 3.141592653589793;
}

extension on double {
  double sin() {
    // Taylor series approximation for sine
    double x = this % (2 * Math.pi);
    if (x > Math.pi) x -= 2 * Math.pi;
    
    double result = x;
    double term = x;
    
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    
    return result;
  }
}
