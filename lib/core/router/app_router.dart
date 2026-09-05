import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animations/animations.dart';
import '../../features/auth/providers/auth_provider.dart'; 
import '../../features/home/presentation/home_shell_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
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
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      
      // Блокуємо доступ до системи, поки йде перевірка токена (фікс Race Condition)
      if (authState.isLoading) {
        return isAuthRoute ? null : '/login';
      }

      final isAuthenticated = authState.valueOrNull ?? false;

      if (!isAuthenticated && !isAuthRoute) return '/login';
      if (isAuthenticated && isAuthRoute) return '/news';
      
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) {
          return HomeShellScreen(navigationShell: navigationShell);
        },
        navigatorContainerBuilder: (context, navigationShell, children) {
          return PageTransitionSwitcher(
            duration: const Duration(milliseconds: 350),
            transitionBuilder: (child, animation, secondaryAnimation) {
              return SharedAxisTransition(
                animation: animation,
                secondaryAnimation: secondaryAnimation,
                transitionType: SharedAxisTransitionType.horizontal,
                fillColor: Theme.of(context).colorScheme.surface,
                child: child,
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(navigationShell.currentIndex),
              child: children[navigationShell.currentIndex],
            ),
          );
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
                    pageBuilder: (context, state) {
                      final newsId = state.pathParameters['id']!;
                      final scrollToComments = state.uri.queryParameters['comments'] == 'true';
                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: NewsDetailScreen(
                          newsId: newsId, 
                          scrollToComments: scrollToComments,
                        ),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return SharedAxisTransition(
                            animation: animation,
                            secondaryAnimation: secondaryAnimation,
                            transitionType: SharedAxisTransitionType.scaled,
                            fillColor: Theme.of(context).colorScheme.surface,
                            child: child,
                          );
                        },
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
                    pageBuilder: (context, state) {
                      final document = state.extra as DocumentModel;
                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: DocumentPdfScreen(document: document),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return SharedAxisTransition(
                            animation: animation,
                            secondaryAnimation: secondaryAnimation,
                            transitionType: SharedAxisTransitionType.scaled,
                            fillColor: Theme.of(context).colorScheme.surface,
                            child: child,
                          );
                        },
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
                path: '/projects',
                builder: (context, state) => const ProjectsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    pageBuilder: (context, state) {
                      final projectId = state.pathParameters['id']!;
                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: ProjectDetailScreen(projectId: projectId),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return SharedAxisTransition(
                            animation: animation,
                            secondaryAnimation: secondaryAnimation,
                            transitionType: SharedAxisTransitionType.scaled,
                            fillColor: Theme.of(context).colorScheme.surface,
                            child: child,
                          );
                        },
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'pdf',
                        pageBuilder: (context, state) {
                          final project = state.extra as ProjectModel;
                          return CustomTransitionPage(
                            key: state.pageKey,
                            child: ProjectPdfScreen(project: project),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return SharedAxisTransition(
                                animation: animation,
                                secondaryAnimation: secondaryAnimation,
                                transitionType: SharedAxisTransitionType.scaled,
                                fillColor: Theme.of(context).colorScheme.surface,
                                child: child,
                              );
                            },
                          );
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
                    pageBuilder: (context, state) {
                      final pollId = state.pathParameters['id']!;
                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: PollDetailScreen(pollId: pollId),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return SharedAxisTransition(
                            animation: animation,
                            secondaryAnimation: secondaryAnimation,
                            transitionType: SharedAxisTransitionType.scaled,
                            fillColor: Theme.of(context).colorScheme.surface,
                            child: child,
                          );
                        },
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
                path: '/chats',
                builder: (context, state) => const ChatsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    pageBuilder: (context, state) {
                      final groupId = state.pathParameters['id']!;
                      return CustomTransitionPage(
                        key: state.pageKey,
                        child: ChatDetailScreen(groupId: groupId),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                          return SharedAxisTransition(
                            animation: animation,
                            secondaryAnimation: secondaryAnimation,
                            transitionType: SharedAxisTransitionType.scaled,
                            fillColor: Theme.of(context).colorScheme.surface,
                            child: child,
                          );
                        },
                      );
                    },
                    routes: [
                      GoRoute(
                        path: 'info',
                        pageBuilder: (context, state) {
                          final groupId = state.pathParameters['id']!;
                          return CustomTransitionPage(
                            key: state.pageKey,
                            child: ChatInfoScreen(groupId: groupId),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return SharedAxisTransition(
                                animation: animation,
                                secondaryAnimation: secondaryAnimation,
                                transitionType: SharedAxisTransitionType.scaled,
                                fillColor: Theme.of(context).colorScheme.surface,
                                child: child,
                              );
                            },
                          );
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