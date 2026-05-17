import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/infrastructure_providers.dart';
import '../prefs/app_prefs.dart';

class ThemeNotifier extends Notifier<ThemeMode> {
  late AppPrefs _prefs;

  @override
  ThemeMode build() {
    _prefs = ref.watch(appPrefsProvider);
    return switch (_prefs.themeMode) {
      AppThemeMode.light => ThemeMode.light,
      AppThemeMode.dark => ThemeMode.dark,
      AppThemeMode.system => ThemeMode.system,
    };
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setThemeMode(switch (mode) {
      ThemeMode.light => AppThemeMode.light,
      ThemeMode.dark => AppThemeMode.dark,
      ThemeMode.system => AppThemeMode.system,
    });
  }
}

final themeModeProvider =
    NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);
