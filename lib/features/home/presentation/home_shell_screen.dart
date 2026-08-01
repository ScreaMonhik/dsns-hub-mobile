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
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.newspaper), label: 'Новини'),
          NavigationDestination(icon: Icon(Icons.description), label: 'Документи'),
          NavigationDestination(icon: Icon(Icons.folder), label: 'Проєкти'),
          NavigationDestination(icon: Icon(Icons.poll), label: 'Опитування'),
          NavigationDestination(icon: Icon(Icons.chat), label: 'Чати'),
        ],
      ),
    );
  }
}