import 'dart:ui' show Locale;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/l10n/locale_notifier.dart';
import '../../../core/theme/theme_notifier.dart';

@immutable
class SettingsViewModel {
  const SettingsViewModel({
    required this.themeMode,
    required this.locale,
    required this.appVersion,
  });

  final ThemeMode themeMode;
  final Locale? locale;
  final String appVersion;
}

class SettingsController extends AsyncNotifier<SettingsViewModel> {
  @override
  Future<SettingsViewModel> build() async {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final info = await PackageInfo.fromPlatform();
    return SettingsViewModel(
      themeMode: themeMode,
      locale: locale,
      appVersion: info.version,
    );
  }

  Future<void> setTheme(ThemeMode mode) async {
    await ref.read(themeModeProvider.notifier).setMode(mode);
    state = AsyncData(
      SettingsViewModel(
        themeMode: mode,
        locale: state.value!.locale,
        appVersion: state.value!.appVersion,
      ),
    );
  }

  Future<void> setLocale(Locale? locale) async {
    await ref.read(localeProvider.notifier).setLocale(locale);
    state = AsyncData(
      SettingsViewModel(
        themeMode: state.value!.themeMode,
        locale: locale,
        appVersion: state.value!.appVersion,
      ),
    );
  }
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, SettingsViewModel>(
  SettingsController.new,
);
