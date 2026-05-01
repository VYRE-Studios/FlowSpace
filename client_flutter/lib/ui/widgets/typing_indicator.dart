import 'package:flutter/material.dart';

class TypingIndicator extends StatelessWidget {
  final List<String> userNames;

  const TypingIndicator({
    Key? key,
    required this.userNames,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (userNames.isEmpty) return const SizedBox.shrink();

    String text;
    if (userNames.length == 1) {
      text = '${userNames[0]} is typing…';
    } else if (userNames.length == 2) {
      text = '${userNames[0]} and ${userNames[1]} are typing…';
    } else {
      text = '${userNames[0]}, ${userNames[1]} and ${userNames.length - 2} others are typing…';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const _AnimatedDots(),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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
        final value = _controller.value;
        final dots = [0, 1, 2].map((i) {
          final opacity = ((value * 3 - i) % 3).clamp(0.0, 1.0);
          return Opacity(
            opacity: opacity,
            child: const Text('•', style: TextStyle(fontSize: 18)),
          );
        }).toList();
        return Row(children: dots);
      },
    );
  }
}
