import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/prefs/app_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences sp;
  late AppPrefs prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    sp = await SharedPreferences.getInstance();
    prefs = AppPrefs(sp);
  });

  test('themeMode defaults to system', () {
    expect(prefs.themeMode, AppThemeMode.system);
  });

  test('themeMode round-trips', () async {
    await prefs.setThemeMode(AppThemeMode.dark);
    expect(prefs.themeMode, AppThemeMode.dark);
  });

  test('locale defaults to null (system)', () {
    expect(prefs.localeTag, isNull);
  });

  test('localeTag round-trips', () async {
    await prefs.setLocaleTag('en');
    expect(prefs.localeTag, 'en');
  });

  test('onboardingCompleted defaults to false', () {
    expect(prefs.onboardingCompleted, isFalse);
  });

  test('onboardingCompleted round-trips', () async {
    await prefs.setOnboardingCompleted(true);
    expect(prefs.onboardingCompleted, isTrue);
    await prefs.setOnboardingCompleted(false);
    expect(prefs.onboardingCompleted, isFalse);
  });
}
