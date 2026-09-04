import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'core/router/app_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'core/theme/theme_provider.dart';
import 'core/presentation/widgets/offline_banner.dart';
import 'core/providers/connectivity_provider.dart';
import 'features/news/presentations/providers/news_providers.dart';
import 'features/documents/presentation/providers/document_providers.dart';
import 'features/projects/presentation/providers/project_providers.dart';
import 'features/polls/presentation/providers/poll_provider.dart';
import 'features/chats/presentation/providers/chat_providers.dart';
import 'core/security/app_lock_provider.dart';
import 'core/presentation/widgets/app_lock_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Ukrainian locale data for DateFormat
  await initializeDateFormatting('uk', null);
  Intl.defaultLocale = 'uk';
  
  runApp(const ProviderScope(child: DsnsHubApp()));
}

class DsnsHubApp extends ConsumerStatefulWidget {
  const DsnsHubApp({super.key});

  @override
  ConsumerState<DsnsHubApp> createState() => _DsnsHubAppState();
}

class _DsnsHubAppState extends ConsumerState<DsnsHubApp> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onPause: () => ref.read(appLockProvider.notifier).onPaused(),
      onResume: () => ref.read(appLockProvider.notifier).onResumed(),
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    // Автоматичне оновлення всіх даних при відновленні інтернету
    ref.listen<AsyncValue<List<ConnectivityResult>>>(connectivityProvider, (previous, next) {
      final prevOffline = previous?.value?.contains(ConnectivityResult.none) ?? false;
      final currentOffline = next.value?.contains(ConnectivityResult.none) ?? false;

      if (prevOffline && !currentOffline && next.value != null && next.value!.isNotEmpty) {
        ref.invalidate(newsListProvider);
        ref.invalidate(documentsListProvider);
        ref.invalidate(projectsListProvider);
        ref.invalidate(pollsProvider);
        ref.invalidate(chatsListProvider);
      }
    });

    return MaterialApp.router(
      title: 'DSNS Hub',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('uk', 'UA'),
      ],
      locale: const Locale('uk', 'UA'),
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E40AF),
          brightness: Brightness.light,
          surface: const Color(0xFFF8FAFC),
          surfaceContainer: Colors.white,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: false, // Вирівнювання по лівому краю
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3B82F6),
          brightness: Brightness.dark,
          surface: const Color(0xFF121212),
          surfaceContainer: const Color(0xFF1E1E1E),
          surfaceContainerHighest: const Color(0xFF2C2C2C),
          outlineVariant: const Color(0xFF333333),
          onSurface: const Color(0xFFF8FAFC),
          onSurfaceVariant: const Color(0xFFA1A1AA),
          primaryContainer: const Color(0xFF1D4ED8).withValues(alpha: 0.3),
          onPrimaryContainer: const Color(0xFFDBEAFE),
          errorContainer: const Color(0xFF7F1D1D).withValues(alpha: 0.4),
          onErrorContainer: const Color(0xFFFCA5A5),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Color(0xFF121212),
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: Color(0xFFF8FAFC),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFF333333),
          thickness: 1,
        ),
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Stack(
            children: [
              Column(
                children: [
                  const GlobalOfflineBanner(),
                  Expanded(child: child ?? const SizedBox.shrink()),
                ],
              ),
              const AppLockOverlay(),
            ],
          ),
        );
      },
    );
  }
}