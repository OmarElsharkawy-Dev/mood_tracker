import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/mood_entry.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/energy_level.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';

void main() {
  MoodEntry validEntry({int intensity = 5, double? sleepHours = 7}) {
    final now = DateTime(2026, 5, 17, 14);
    return MoodEntry(
      id: 'abc',
      occurredAt: now,
      mood: Mood.good,
      intensity: intensity,
      note: 'hi',
      tags: const [],
      sleepHours: sleepHours,
      energy: EnergyLevel.medium,
      createdAt: now,
      updatedAt: now,
    );
  }

  group('MoodEntry.validate', () {
    test('returns no errors for a valid entry', () {
      expect(validEntry().validate(), isEmpty);
    });

    test('flags intensity below 1', () {
      expect(validEntry(intensity: 0).validate(), contains('intensity'));
    });

    test('flags intensity above 10', () {
      expect(validEntry(intensity: 11).validate(), contains('intensity'));
    });

    test('flags negative sleepHours', () {
      expect(validEntry(sleepHours: -1).validate(), contains('sleepHours'));
    });

    test('flags sleepHours over 24', () {
      expect(validEntry(sleepHours: 25).validate(), contains('sleepHours'));
    });

    test('allows null sleepHours', () {
      expect(validEntry(sleepHours: null).validate(), isEmpty);
    });
  });

  test('copyWith mutates only the supplied fields', () {
    final original = validEntry();
    final mutated = original.copyWith(mood: Mood.awful);
    expect(mutated.mood, Mood.awful);
    expect(mutated.id, original.id);
  });
}
