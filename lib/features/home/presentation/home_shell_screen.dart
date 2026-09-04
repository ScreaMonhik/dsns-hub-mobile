import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      final activeColor = isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface;
      final inactiveColor = theme.colorScheme.onSurfaceVariant;

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
                ? theme.colorScheme.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive ? activeColor : inactiveColor,
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
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20, 
            right: 20, 
            bottom: MediaQuery.paddingOf(context).bottom + 16, 
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant,
                    width: 0.5,
                  ),
                ),
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
          ),
        ),
      ),
    );
  }
}