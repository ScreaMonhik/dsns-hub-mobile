import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'core/presentation/widgets/offline_banner.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: DsnsHubApp()));
}

class DsnsHubApp extends ConsumerWidget {
  const DsnsHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'DSNS Hub',
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
          seedColor: const Color(0xFF3B82F6), // Сучасний синій акцент
          brightness: Brightness.dark,
          surface: Colors.black, // Абсолютно чорний фон (OLED-friendly)
          surfaceContainer: const Color(0xFF1C1C1E), // Класичний iOS-графіт для карток
          surfaceContainerHighest: const Color(0xFF2C2C2E), // Елементи взаємодії
          outlineVariant: const Color(0xFF38383A), // Витончені бордери карток
          onSurface: Colors.white,
          onSurfaceVariant: const Color(0xFF8E8E93), // М'який сірий для другорядного тексту
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          centerTitle: false, // Вирівнювання по лівому краю
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.black,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
            color: Colors.white,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF0A0A0A), // Трохи світліший за фон екрану
          indicatorColor: const Color(0xFF3B82F6).withValues(alpha: 0.15), // Напівпрозорий індикатор замість суцільної пілюлі
          surfaceTintColor: Colors.transparent,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6));
            }
            return const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF8E8E93));
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFF3B82F6), size: 26);
            }
            return const IconThemeData(color: Color(0xFF8E8E93), size: 26);
          }),
        ),
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              const GlobalOfflineBanner(),
              Expanded(child: child ?? const SizedBox.shrink()),
            ],
          ),
        );
      },
    );
  }
}