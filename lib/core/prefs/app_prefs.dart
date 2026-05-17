import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode { light, dark, system }

class AppPrefs {
  AppPrefs(this._sp);

  final SharedPreferences _sp;

  static const _kThemeMode = 'app.themeMode';
  static const _kLocaleTag = 'app.localeTag';

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
}
