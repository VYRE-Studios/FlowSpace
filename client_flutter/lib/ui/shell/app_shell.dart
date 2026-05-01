import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../screens/workspace_screen.dart';
import '../screens/streams_screen.dart';
import '../screens/vault_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/projects_screen.dart';
import '../views/meet_view.dart';
import '../views/calendar_view.dart';

/// Main FlowSpace application shell with persistent left navigation
/// Version 2.0.0 - Complete application structure
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  // Main navigation tabs
  final List<_NavItem> _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Workspace',
      tooltip: 'Workspace',
    ),
    _NavItem(
      icon: Icons.chat_bubble_outline,
      activeIcon: Icons.chat_bubble,
      label: 'Streams',
      tooltip: 'Streams',
    ),
    _NavItem(
      icon: Icons.video_call_outlined,
      activeIcon: Icons.video_call,
      label: 'Connect',
      tooltip: 'Connect',
    ),
    _NavItem(
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Calendar',
      tooltip: 'Calendar',
    ),
    _NavItem(
      icon: Icons.folder_outlined,
      activeIcon: Icons.folder,
      label: 'Vault',
      tooltip: 'Vault',
    ),
    _NavItem(
      icon: Icons.apps_outlined,
      activeIcon: Icons.apps,
      label: 'Projects',
      tooltip: 'Projects',
    ),
  ];

  final List<_NavItem> _bottomNavItems = [
    _NavItem(
      icon: Icons.settings_outlined,
      activeIcon: Icons.settings,
      label: 'Settings',
      tooltip: 'Settings',
    ),
  ];

  Widget _getScreen(int index) {
    switch (index) {
      case 0: // Workspace (Landing page)
        return const WorkspaceScreen();
      case 1: // Streams (Messaging)
        return const StreamsScreen();
      case 2: // Connect (Video/Voice)
        return const MeetView();
      case 3: // Calendar  
        return const CalendarView();
      case 4: // Vault (Files)
        return const VaultScreen();
      case 5: // Projects
        return const ProjectsScreen();
      case 6: // Settings
        return const SettingsScreen();
      default:
        return const WorkspaceScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: WindowBorder(
        color: const Color(0xFF333333),
        width: 1,
        child: Container(
          // Premium charcoal gradient background
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.bgTop,
                AppColors.bgBottom,
              ],
            ),
          ),
          child: Column(
            children: [
              // Custom Window Title Bar
              WindowTitleBarBox(
                child: Row(
                  children: [
                    Expanded(child: MoveWindow()),
                    const WindowButtons(),
                  ],
                ),
              ),
              
              // Main Content Area
              Expanded(
                child: Row(
                  children: [
                    // Premium sidebar with refined material
                    Container(
                      width: 72,
                      decoration: const BoxDecoration(
                        color: AppColors.sidebar,
                        border: Border(
                          right: BorderSide(
                            color: AppColors.borderSoft,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          
                          // Main navigation items
                          Expanded(
                            child: ListView.builder(
                              itemCount: _navItems.length,
                              itemBuilder: (context, index) {
                                final item = _navItems[index];
                                final isSelected = _selectedIndex == index;
                                
                                return _NavButton(
                                  item: item,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      _selectedIndex = index;
                                    });
                                  },
                                );
                              },
                            ),
                          ),
                          
                          // Bottom navigation items
                          ...List.generate(_bottomNavItems.length, (index) {
                            final item = _bottomNavItems[index];
                            final actualIndex = _navItems.length + index;
                            final isSelected = _selectedIndex == actualIndex;
                            
                            return _NavButton(
                              item: item,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  _selectedIndex = actualIndex;
                                });
                              },
                            );
                          }),
                          
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                    
                    // Main content area
                    Expanded(
                      child: _getScreen(_selectedIndex),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class WindowButtons extends StatelessWidget {
  const WindowButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final buttonColors = WindowButtonColors(
      iconNormal: const Color(0xFFC0C0C0),
      mouseOver: const Color(0xFF404040),
      mouseDown: const Color(0xFF202020),
      iconMouseOver: const Color(0xFFFFFFFF),
      iconMouseDown: const Color(0xFFF0F0F0),
    );

    final closeButtonColors = WindowButtonColors(
      mouseOver: const Color(0xFFD32F2F),
      mouseDown: const Color(0xFFB71C1C),
      iconNormal: const Color(0xFFC0C0C0),
      iconMouseOver: Colors.white,
    );

    return Row(
      children: [
        MinimizeWindowButton(colors: buttonColors),
        MaximizeWindowButton(colors: buttonColors),
        CloseWindowButton(colors: closeButtonColors),
      ],
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String tooltip;

  _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.tooltip,
  });
}

class _NavButton extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.item.tooltip,
      preferBelow: false,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: SizedBox(
            width: 48,
            height: 56, // Increased spacing between icons (20% more)
            child: Stack(
              children: [
                // Premium active indicator - thin machined line
                if (widget.isSelected)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 3,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                // Icon and label container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeInOut, // Precision engineered motion
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? AppColors.selectedOverlay // 10% primary
                        : (_isHovered
                            ? AppColors.hoverOverlay // 3% white
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.isSelected ? widget.item.activeIcon : widget.item.icon,
                          color: widget.isSelected
                              ? AppColors.primary
                              : Colors.white.withOpacity(0.4), // 40% opacity inactive
                          size: 22, // Refined icon size
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.item.label,
                          style: TextStyle(
                            color: widget.isSelected
                                ? AppColors.primary
                                : Colors.white.withOpacity(0.4),
                            fontSize: 11,
                            fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                            letterSpacing: 0.25, // Refined typography
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
