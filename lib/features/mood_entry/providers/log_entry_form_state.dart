import 'package:flutter/foundation.dart';

import '../domain/entities/mood_entry.dart';
import '../domain/entities/tag.dart';
import '../domain/enums/energy_level.dart';
import '../domain/enums/mood.dart';

@immutable
class LogEntryFormState {
  const LogEntryFormState({
    required this.occurredAt,
    required this.mood,
    required this.intensity,
    required this.energy,
    required this.note,
    required this.tags,
    required this.sleepHours,
  });

  factory LogEntryFormState.blank(DateTime now) => LogEntryFormState(
        occurredAt: now,
        mood: null,
        intensity: 5,
        energy: EnergyLevel.medium,
        note: '',
        tags: const [],
        sleepHours: null,
      );

  final DateTime occurredAt;
  final Mood? mood;
  final int intensity;
  final EnergyLevel energy;
  final String note;
  final List<Tag> tags;
  final double? sleepHours;

  Map<String, String> get errors {
    final e = <String, String>{};
    if (intensity < 1 || intensity > 10) e['intensity'] = 'out_of_range';
    if (sleepHours != null && (sleepHours! < 0 || sleepHours! > 24)) {
      e['sleepHours'] = 'out_of_range';
    }
    return e;
  }

  bool get canSubmit => mood != null && errors.isEmpty;

  MoodEntry? toEntity({required String id, required DateTime now}) {
    if (mood == null) return null;
    return MoodEntry(
      id: id,
      occurredAt: occurredAt,
      mood: mood!,
      intensity: intensity,
      note: note.isEmpty ? null : note,
      tags: tags,
      sleepHours: sleepHours,
      energy: energy,
      createdAt: now,
      updatedAt: now,
    );
  }

  LogEntryFormState copyWith({
    DateTime? occurredAt,
    Mood? mood,
    int? intensity,
    EnergyLevel? energy,
    String? note,
    List<Tag>? tags,
    double? sleepHours,
    bool clearSleepHours = false,
  }) {
    return LogEntryFormState(
      occurredAt: occurredAt ?? this.occurredAt,
      mood: mood ?? this.mood,
      intensity: intensity ?? this.intensity,
      energy: energy ?? this.energy,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      sleepHours: clearSleepHours ? null : (sleepHours ?? this.sleepHours),
    );
  }
}
