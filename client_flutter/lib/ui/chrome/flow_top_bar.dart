import 'package:flutter/material.dart';
import '../../core/theme/flo_theme.dart';

/// FlowSpace top bar - Δ-PM2.E
/// Signature chrome with left/center/right clusters
class FlowTopBar extends StatelessWidget {
  final String title;
  final String? contextText;
  final List<Widget> actions;

  const FlowTopBar({
    super.key,
    required this.title,
    this.contextText,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          _buildLeft(context),
          const Expanded(child: SizedBox()),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: actions,
          ),
        ],
      ),
    );
  }

  Widget _buildLeft(BuildContext context) {
    return Row(
      children: [
        Text(title, style: FloTheme.displaySmall),
        if (contextText != null) ...[
          const SizedBox(width: 12),
          Text(
            contextText!,
            style: FloTheme.caption,
          ),
        ],
      ],
    );
  }
}
