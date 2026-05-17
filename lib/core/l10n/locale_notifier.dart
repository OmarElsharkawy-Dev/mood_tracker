import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/infrastructure_providers.dart';
import '../prefs/app_prefs.dart';

class LocaleNotifier extends Notifier<Locale?> {
  late AppPrefs _prefs;

  @override
  Locale? build() {
    _prefs = ref.watch(appPrefsProvider);
    final tag = _prefs.localeTag;
    return tag == null ? null : Locale(tag);
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    await _prefs.setLocaleTag(locale?.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(LocaleNotifier.new);
