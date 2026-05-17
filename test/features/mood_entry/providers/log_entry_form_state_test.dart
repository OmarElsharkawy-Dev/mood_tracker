import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/mood_entry/providers/log_entry_form_state.dart';

void main() {
  test('blank default has no errors but is incomplete', () {
    final s = LogEntryFormState.blank(DateTime(2026, 5, 17));
    expect(s.errors, isEmpty);
    expect(s.canSubmit, isFalse, reason: 'mood not chosen');
  });

  test('canSubmit becomes true once mood is set', () {
    final s = LogEntryFormState.blank(DateTime(2026, 5, 17))
        .copyWith(mood: Mood.good);
    expect(s.canSubmit, isTrue);
  });

  test('intensity out of range flags error and blocks submit', () {
    final s = LogEntryFormState.blank(DateTime(2026, 5, 17))
        .copyWith(mood: Mood.good, intensity: 0);
    expect(s.errors.containsKey('intensity'), isTrue);
    expect(s.canSubmit, isFalse);
  });

  test('sleepHours out of range flags error', () {
    final s = LogEntryFormState.blank(DateTime(2026, 5, 17))
        .copyWith(mood: Mood.good, sleepHours: 30);
    expect(s.errors.containsKey('sleepHours'), isTrue);
  });

  test('toEntity builds a valid MoodEntry when canSubmit', () {
    final s = LogEntryFormState.blank(DateTime(2026, 5, 17)).copyWith(
      mood: Mood.good,
      energy: EnergyLevel.high,
      intensity: 7,
      note: 'fine',
      sleepHours: 7.5,
    );
    final entity = s.toEntity(id: 'e1', now: DateTime(2026, 5, 17, 14));
    expect(entity, isNotNull);
    expect(entity!.id, 'e1');
    expect(entity.mood, Mood.good);
    expect(entity.intensity, 7);
  });
}
