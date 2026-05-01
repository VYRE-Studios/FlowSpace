import 'package:flutter/material.dart';
import '../../core/theme/flo_theme.dart';

/// Sidebar section header - Δ-PM2.A
/// Uppercase labels for internal organization
class SidebarSectionHeader extends StatelessWidget {
  final String text;

  const SidebarSectionHeader({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        style: FloTheme.textSidebarSection,
      ),
    );
  }
}
