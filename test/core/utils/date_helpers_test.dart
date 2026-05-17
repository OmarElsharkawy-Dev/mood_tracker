import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/utils/date_helpers.dart';

void main() {
  group('DateHelpers', () {
    test('startOfDay zeros hours/minutes/seconds/ms', () {
      final d = DateTime(2026, 5, 17, 14, 23, 45, 678);
      expect(startOfDay(d), DateTime(2026, 5, 17));
    });

    test('endOfDay is just before midnight', () {
      final d = DateTime(2026, 5, 17, 1);
      expect(endOfDay(d), DateTime(2026, 5, 17, 23, 59, 59, 999));
    });

    test('isSameDay treats different times on same date as same', () {
      expect(
        isSameDay(DateTime(2026, 5, 17, 1), DateTime(2026, 5, 17, 23)),
        isTrue,
      );
      expect(
        isSameDay(DateTime(2026, 5, 17), DateTime(2026, 5, 18)),
        isFalse,
      );
    });
  });
}
