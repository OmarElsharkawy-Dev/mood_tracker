import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

class AppPrefs {
  AppPrefs(this._sp);

  final SharedPreferences _sp;

  static const _kThemeMode = 'app.themeMode';
  static const _kLocaleTag = 'app.localeTag';
  static const _kOnboardingCompleted = 'app.onboardingCompleted';
  static const _kReminderEnabled = 'app.reminderEnabled';
  static const _kReminderTime = 'app.reminderTime';

  AppThemeMode get themeMode {
    final raw = _sp.getString(_kThemeMode);
    return switch (raw) {
      'light' => AppThemeMode.light,
      'dark' => AppThemeMode.dark,
      _ => AppThemeMode.system,
    };
  }

  Future<void> setThemeMode(AppThemeMode mode) =>
      _sp.setString(_kThemeMode, mode.name);

  String? get localeTag => _sp.getString(_kLocaleTag);

  Future<void> setLocaleTag(String? tag) async {
    if (tag == null) {
      await _sp.remove(_kLocaleTag);
    } else {
      await _sp.setString(_kLocaleTag, tag);
    }
  }

  bool get onboardingCompleted =>
      _sp.getBool(_kOnboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted(bool value) =>
      _sp.setBool(_kOnboardingCompleted, value);

  bool get reminderEnabled => _sp.getBool(_kReminderEnabled) ?? false;

  Future<void> setReminderEnabled(bool value) =>
      _sp.setBool(_kReminderEnabled, value);

  String? get reminderTime => _sp.getString(_kReminderTime);

  Future<void> setReminderTime(String? hhmm) async {
    if (hhmm == null) {
      await _sp.remove(_kReminderTime);
    } else {
      await _sp.setString(_kReminderTime, hhmm);
    }
  }
}
