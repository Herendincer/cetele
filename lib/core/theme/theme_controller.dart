import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { system, light, dark }

extension AppThemeModeLabel on AppThemeMode {
  String get label => switch (this) {
        AppThemeMode.system => 'Sistem Teması',
        AppThemeMode.light => 'Aydınlık Tema',
        AppThemeMode.dark => 'Karanlık Tema',
      };

  ThemeMode get themeMode => switch (this) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };
}

final themeControllerProvider = NotifierProvider<ThemeController, AppThemeMode>(
  ThemeController.new,
);

class ThemeController extends Notifier<AppThemeMode> {
  static const _preferenceKey = 'theme_mode';

  @override
  AppThemeMode build() {
    _loadPreference();
    return AppThemeMode.system;
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = mode;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, mode.name);
  }

  Future<void> _loadPreference() async {
    final preferences = await SharedPreferences.getInstance();
    final savedMode = preferences.getString(_preferenceKey);
    final mode = AppThemeMode.values.where((value) => value.name == savedMode).firstOrNull;
    if (mode != null && ref.mounted) state = mode;
  }
}