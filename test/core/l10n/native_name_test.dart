import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/l10n/native_name.dart';

void main() {
  test('returns native name for English', () {
    expect(nativeNameFor(const Locale('en')), 'English');
  });

  test('returns native name for Spanish', () {
    expect(nativeNameFor(const Locale('es')), 'Español');
  });

  test('falls back to language code for unknown locale', () {
    expect(nativeNameFor(const Locale('fr')), 'fr');
  });
}
