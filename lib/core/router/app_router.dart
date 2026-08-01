import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/home/presentation/home_shell_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/news',
    redirect: (context, state) {
      final isAuth = authState == AuthState.authenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isInitial = authState == AuthState.initial;

      if (isInitial) return null; // Wait for secure storage check
      if (!isAuth && !isLoggingIn) return '/login';
      if (isAuth && isLoggingIn) return '/news';
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                // TODO: Реалізувати виклик API логіну. 
                // Поки що це мок для перевірки навігації.
                ref.read(authProvider.notifier).loginUser('mock_jwt_token');
              },
              child: const Text('Login Mock'),
            ),
          ),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/news',
                builder: (context, state) => const Scaffold(body: Center(child: Text('Новини'))),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/documents',
                builder: (context, state) => const Scaffold(body: Center(child: Text('Документи'))),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects',
                builder: (context, state) => const Scaffold(body: Center(child: Text('Проєкти'))),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/polls',
                builder: (context, state) => const Scaffold(body: Center(child: Text('Опитування'))),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/chats',
                builder: (context, state) => const Scaffold(body: Center(child: Text('Чати'))),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});