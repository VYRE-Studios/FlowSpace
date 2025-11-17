import 'package:flutter/material.dart';

/// Search bar placeholder shown in the header.
///
/// Real search wiring will be added later; for now this acts as an
/// integration point and visual affordance.
class HeaderSearchBar extends StatelessWidget {
  final VoidCallback? onTap;

  const HeaderSearchBar({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search, color: Colors.white70, size: 18),
            SizedBox(width: 10),
            Text(
              'Search…',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}


