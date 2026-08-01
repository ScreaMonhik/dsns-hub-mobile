import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// Оновіть шлях імпорту до вашого auth_provider.dart, якщо він знаходиться в іншій папці
import '../../features/auth/providers/auth_provider.dart'; 
import '../../features/home/presentation/home_shell_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/polls/presentation/screens/polls_screen.dart';
import '../../features/polls/presentation/screens/poll_detail_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/news',
    redirect: (context, state) {
      if (authState is AsyncLoading) return null; 

      final isAuthenticated = authState.valueOrNull ?? false;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoggingIn) return '/login';
      if (isAuthenticated && isLoggingIn) return '/news';
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
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
                builder: (context, state) => const PollsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final pollId = state.pathParameters['id']!;
                      return PollDetailScreen(pollId: pollId);
                    },
                  ),
                ],
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