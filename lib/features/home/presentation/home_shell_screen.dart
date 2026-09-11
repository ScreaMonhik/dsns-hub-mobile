import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'widgets/liquid_glass_home_tab_bar.dart';

class HomeShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShellScreen({
    super.key,
    required this.navigationShell,
  });

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
      final isActive = navigationShell.currentIndex == index;
      final activeColor = theme.colorScheme.primary;

      return GestureDetector(
        onTap: () => _goBranch(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: isActive ? 16 : 8,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary.withValues(alpha: 0.14)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? activeColor : null,
                size: 26,
              ),
              ClipRect(
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  widthFactor: isActive ? 1.0 : 0.0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: activeColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(child: navigationShell),
          LiquidGlassHomeTabBar(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildNavItem(0, Icons.newspaper_outlined, Icons.newspaper, 'Новини'),
                  buildNavItem(1, Icons.description_outlined, Icons.description, 'Документи'),
                  buildNavItem(2, Icons.folder_outlined, Icons.folder, 'Проєкти'),
                  buildNavItem(3, Icons.poll_outlined, Icons.poll, 'Опитування'),
                  buildNavItem(4, Icons.chat_bubble_outline, Icons.chat_bubble, 'Чати'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
