import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
// Оновіть шлях імпорту до вашого auth_provider.dart, якщо він знаходиться в іншій папці
import '../../features/auth/providers/auth_provider.dart'; 
import '../../features/home/presentation/home_shell_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/polls/presentation/screens/polls_screen.dart';
import '../../features/polls/presentation/screens/poll_detail_screen.dart';
import '../../features/news/presentations/screens/news_screen.dart';
import '../../features/news/presentations/screens/news_detail_screen.dart';
import '../../features/chats/presentation/screens/chats_screen.dart';
import '../../features/chats/presentation/screens/chat_detail_screen.dart';
import '../../features/chats/presentation/screens/chat_info_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/documents/presentation/screens/documents_screen.dart';
import '../../features/documents/presentation/screens/document_pdf_screen.dart';
import '../../features/documents/data/models/document_models.dart';
import '../../features/projects/presentation/screens/projects_screen.dart';
import '../../features/projects/presentation/screens/project_detail_screen.dart';
import '../../features/projects/presentation/screens/project_pdf_screen.dart';
import '../../features/projects/data/models/project_models.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Використовуємо ValueNotifier, щоб GoRouter реагував на зміни без перестворення самого себе
  final authStateNotifier = ValueNotifier<AsyncValue<bool>>(const AsyncValue.loading());
  
  ref.onDispose(() {
    authStateNotifier.dispose();
  });

  ref.listen(authStateProvider, (previous, next) {
    authStateNotifier.value = next;
  });

  return GoRouter(
    initialLocation: '/news',
    refreshListenable: authStateNotifier,
    redirect: (context, state) {
      final authState = authStateNotifier.value;
      final isLoggingIn = state.matchedLocation == '/login';
      
      // Блокуємо доступ до системи, поки йде перевірка токена (фікс Race Condition)
      if (authState.isLoading) {
        return isLoggingIn ? null : '/login';
      }

      final isAuthenticated = authState.valueOrNull ?? false;

      if (!isAuthenticated && !isLoggingIn) return '/login';
      if (isAuthenticated && isLoggingIn) return '/news';
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
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
                builder: (context, state) => const NewsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final newsId = state.pathParameters['id']!;
                      final scrollToComments = state.uri.queryParameters['comments'] == 'true';
                      return NewsDetailScreen(
                        newsId: newsId, 
                        scrollToComments: scrollToComments,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/documents',
                builder: (context, state) => const DocumentsScreen(),
                routes: [
                  GoRoute(
                    path: 'view',
                    builder: (context, state) {
                      final document = state.extra as DocumentModel;
                      return DocumentPdfScreen(document: document);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/projects',
                builder: (context, state) => const ProjectsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final projectId = state.pathParameters['id']!;
                      return ProjectDetailScreen(projectId: projectId);
                    },
                    routes: [
                      GoRoute(
                        path: 'pdf',
                        builder: (context, state) {
                          final project = state.extra as ProjectModel;
                          return ProjectPdfScreen(project: project);
                        },
                      ),
                    ],
                  ),
                ],
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
                builder: (context, state) => const ChatsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final groupId = state.pathParameters['id']!;
                      return ChatDetailScreen(groupId: groupId);
                    },
                    routes: [
                      GoRoute(
                        path: 'info',
                        builder: (context, state) {
                          final groupId = state.pathParameters['id']!;
                          return ChatInfoScreen(groupId: groupId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});