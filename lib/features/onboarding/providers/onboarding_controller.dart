import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/infrastructure_providers.dart';
import '../../../core/prefs/app_prefs.dart';

class OnboardingController extends Notifier<int> {
  late AppPrefs _prefs;

  @override
  int build() {
    _prefs = ref.watch(appPrefsProvider);
    return 0;
  }

  void setPage(int page) => state = page;

  Future<void> complete() => _prefs.setOnboardingCompleted(true);
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, int>(OnboardingController.new);
