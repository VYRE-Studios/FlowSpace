import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class FlowNavRail extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const FlowNavRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'icon': 'dashboard', 'label': 'Dashboard'},
      {'icon': 'projects', 'label': 'Projects'},
      {'icon': 'chat', 'label': 'Chat'},
      {'icon': 'meet', 'label': 'Meet'},
      {'icon': 'vault', 'label': 'Vault'},
      {'icon': 'calendar', 'label': 'Calendar'},
      {'icon': 'settings', 'label': 'Settings'},
    ];

    return Container(
      width: 96,
      color: const Color(0xFF1A1A1A),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: InkWell(
                onTap: () => onDestinationSelected(i),
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: i == selectedIndex
                        ? const Color(0xFF0066FF).withValues(alpha: 0.2)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: SvgPicture.asset(
                    'assets/icons/${items[i]['icon']}.svg',
                    width: 28,
                    colorFilter: ColorFilter.mode(
                      i == selectedIndex
                          ? const Color(0xFF0066FF)
                          : Colors.white.withValues(alpha: 0.65),
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

