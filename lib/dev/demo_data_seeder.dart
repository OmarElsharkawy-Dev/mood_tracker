import 'dart:math';

import '../core/utils/uuid.dart';
import '../features/mood_entry/domain/entities/mood_entry.dart';
import '../features/mood_entry/domain/entities/tag.dart';
import '../features/mood_entry/domain/enums/energy_level.dart';
import '../features/mood_entry/domain/enums/mood.dart';
import '../features/mood_entry/domain/repositories/mood_entry_repository.dart';

/// Seeds the repository with ~150 realistic mood entries spanning the last
/// 6 months. Intended for development and design-preview use only — gated
/// behind `kDebugMode` at the call site.
///
/// Existing entries are NOT cleared. Tapping multiple times keeps appending,
/// which is acceptable for a dev tool; reset via the UI's delete affordance
/// or by reinstalling the app.
///
/// Returns the number of entries successfully inserted.
Future<int> seedDemoData(MoodEntryRepository repo, {int? seed}) async {
  final rng = Random(seed ?? DateTime.now().millisecondsSinceEpoch);
  final today = DateTime.now();
  final start = DateTime(today.year, today.month - 6, today.day);

  // Sample tag pool (slug, label). Reused across entries; tags are
  // user-created text, so they don't go through l10n.
  const tagPool = <(String, String)>[
    ('work', 'Work'),
    ('family', 'Family'),
    ('exercise', 'Exercise'),
    ('friends', 'Friends'),
    ('rest', 'Rest'),
    ('reading', 'Reading'),
    ('outside', 'Outside'),
    ('food', 'Food'),
  ];
  final tagsBySlug = {
    for (final t in tagPool)
      t.$1: Tag(id: 't_${t.$1}', slug: t.$1, label: t.$2),
  };

  // Sample note pool. Empty strings let some entries have no note.
  const notePool = <String>[
    'Slept well, feeling refreshed.',
    'Long day at work but it went OK.',
    'Caught up with family for dinner.',
    'Quick walk in the park helped.',
    'Stuck on a problem all afternoon.',
    'Read a few chapters in the evening.',
    'Felt off without knowing why.',
    'Great workout this morning.',
    'Watched a movie tonight.',
    'Too much coffee, restless.',
    'Quiet day, mostly rest.',
    '',
    '',
    '',
  ];

  // Weighted distributions: leans toward okay/good for moods and
  // low/medium for energy — feels more realistic than uniform.
  Mood randomMood() {
    final r = rng.nextDouble();
    if (r < 0.05) return Mood.awful;
    if (r < 0.20) return Mood.bad;
    if (r < 0.50) return Mood.okay;
    if (r < 0.85) return Mood.good;
    return Mood.great;
  }

  EnergyLevel randomEnergy() {
    final r = rng.nextDouble();
    if (r < 0.10) return EnergyLevel.veryLow;
    if (r < 0.30) return EnergyLevel.low;
    if (r < 0.65) return EnergyLevel.medium;
    if (r < 0.90) return EnergyLevel.high;
    return EnergyLevel.veryHigh;
  }

  int created = 0;
  final dayCount = today.difference(start).inDays + 1;
  for (var d = 0; d < dayCount; d++) {
    final day = DateTime(start.year, start.month, start.day + d);
    if (day.isAfter(today)) break;

    // ~70% of days have at least one entry.
    if (rng.nextDouble() > 0.70) continue;

    // 1 entry most of the time, occasionally 2-3.
    final entriesToday = rng.nextInt(10) < 7
        ? 1
        : (rng.nextInt(10) < 7 ? 2 : 3);

    for (var i = 0; i < entriesToday; i++) {
      final hour = 8 + rng.nextInt(14); // 08:00–21:59
      final minute = rng.nextInt(60);
      final occurredAt =
          DateTime(day.year, day.month, day.day, hour, minute);

      // ~60% of entries have 1–3 tags.
      final tags = <Tag>[];
      if (rng.nextDouble() < 0.60) {
        final n = 1 + rng.nextInt(3);
        final shuffled = [...tagsBySlug.values]..shuffle(rng);
        tags.addAll(shuffled.take(n));
      }

      // ~70% of entries have sleep hours (5.0–9.5).
      final sleepHours = rng.nextDouble() < 0.70
          ? 5.0 + rng.nextDouble() * 4.5
          : null;

      final note = notePool[rng.nextInt(notePool.length)];

      final entry = MoodEntry(
        id: generateId(),
        occurredAt: occurredAt,
        mood: randomMood(),
        intensity: 3 + rng.nextInt(6), // 3–8
        note: note.isEmpty ? null : note,
        tags: tags,
        sleepHours: sleepHours == null
            ? null
            : double.parse(sleepHours.toStringAsFixed(1)),
        energy: randomEnergy(),
        createdAt: occurredAt,
        updatedAt: occurredAt,
      );

      final (_, err) = await repo.create(entry);
      if (err == null) created++;
    }
  }

  return created;
}
