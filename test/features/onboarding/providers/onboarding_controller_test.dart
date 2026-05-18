import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/di/infrastructure_providers.dart';
import 'package:mood_tracker/core/prefs/app_prefs.dart';
import 'package:mood_tracker/features/onboarding/providers/onboarding_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppPrefs prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final sp = await SharedPreferences.getInstance();
    prefs = AppPrefs(sp);
    container = ProviderContainer(overrides: [
      appPrefsProvider.overrideWithValue(prefs),
    ]);
  });

  tearDown(() => container.dispose());

  test('initial page is 0', () {
    container.read(onboardingControllerProvider.notifier);
    expect(container.read(onboardingControllerProvider), 0);
  });

  test('setPage updates state', () {
    final notifier = container.read(onboardingControllerProvider.notifier);
    notifier.setPage(2);
    expect(container.read(onboardingControllerProvider), 2);
  });

  test('complete writes onboardingCompleted to prefs', () async {
    final notifier = container.read(onboardingControllerProvider.notifier);
    await notifier.complete();
    expect(prefs.onboardingCompleted, isTrue);
  });
}
