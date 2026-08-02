import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage_provider.dart';

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier(ref);
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  final Ref _ref;
  static const _themeKey = 'app_theme_mode';

  ThemeNotifier(this._ref) : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final storage = _ref.read(secureStorageProvider);
    final savedTheme = await storage.read(key: _themeKey);
    if (savedTheme != null) {
      state = _parseThemeMode(savedTheme);
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final storage = _ref.read(secureStorageProvider);
    await storage.write(key: _themeKey, value: mode.name);
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}