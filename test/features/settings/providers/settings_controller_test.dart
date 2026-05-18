import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/di/infrastructure_providers.dart';
import 'package:mood_tracker/core/prefs/app_prefs.dart';
import 'package:mood_tracker/features/settings/providers/settings_controller.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences sp;
  late AppPrefs prefs;
  late ProviderContainer container;

  setUp(() async {
    PackageInfo.setMockInitialValues(
      appName: 'mood_tracker',
      packageName: 'com.example.mood_tracker',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    SharedPreferences.setMockInitialValues({});
    sp = await SharedPreferences.getInstance();
    prefs = AppPrefs(sp);
    container = ProviderContainer(overrides: [
      appPrefsProvider.overrideWithValue(prefs),
    ]);
  });

  tearDown(() => container.dispose());

  test('build returns the current theme, locale, and app version', () async {
    final vm = await container.read(settingsControllerProvider.future);
    expect(vm.themeMode, ThemeMode.system);
    expect(vm.locale, isNull);
    expect(vm.appVersion, '1.0.0');
  });

  test('setTheme updates the underlying provider and persists', () async {
    final notifier = container.read(settingsControllerProvider.notifier);
    await container.read(settingsControllerProvider.future);
    await notifier.setTheme(ThemeMode.dark);
    final vm = await container.read(settingsControllerProvider.future);
    expect(vm.themeMode, ThemeMode.dark);
    expect(prefs.themeMode, AppThemeMode.dark);
  });

  test('setLocale updates the underlying provider and persists', () async {
    final notifier = container.read(settingsControllerProvider.notifier);
    await container.read(settingsControllerProvider.future);
    await notifier.setLocale(const Locale('es'));
    final vm = await container.read(settingsControllerProvider.future);
    expect(vm.locale, const Locale('es'));
    expect(prefs.localeTag, 'es');
  });
}
