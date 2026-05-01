import 'package:flutter/material.dart';
import '../../core/theme/flo_theme.dart';
import '../constants/colors.dart';

/// Premium sidebar container - Δ-PM2.A
/// Deeper carbon surface with refined material definition
class FlowSidebar extends StatelessWidget {
  final List<Widget> children;

  const FlowSidebar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      decoration: const BoxDecoration(
        color: AppColors.bgSidebar, // Deeper carbon tier
        border: Border(
          right: BorderSide(
            color: AppColors.borderLow,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          _buildBrandHeader(context),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: children),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHeader(BuildContext context) {
    return Column(
      children: [
        Icon(
          Icons.widgets_outlined, // Placeholder - replace with FloIcons.flowspaceMark
          size: 28,
          color: AppColors.textPrimary,
        ),
        const SizedBox(height: 10),
        Text(
          'FlowSpace',
          style: FloTheme.textCapsHeader,
        ),
      ],
    );
  }
}
