import 'package:flutter/foundation.dart';

import '../enums/energy_level.dart';
import '../enums/mood.dart';
import 'tag.dart';

@immutable
class MoodEntry {
  const MoodEntry({
    required this.id,
    required this.occurredAt,
    required this.mood,
    required this.intensity,
    required this.note,
    required this.tags,
    required this.sleepHours,
    required this.energy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final DateTime occurredAt;
  final Mood mood;
  final int intensity;
  final String? note;
  final List<Tag> tags;
  final double? sleepHours;
  final EnergyLevel energy;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns a map of field-name → error key. Empty map ⇒ valid.
  Map<String, String> validate() {
    final errors = <String, String>{};
    if (intensity < 1 || intensity > 10) {
      errors['intensity'] = 'out_of_range';
    }
    if (sleepHours != null && (sleepHours! < 0 || sleepHours! > 24)) {
      errors['sleepHours'] = 'out_of_range';
    }
    return errors;
  }

  MoodEntry copyWith({
    String? id,
    DateTime? occurredAt,
    Mood? mood,
    int? intensity,
    String? note,
    List<Tag>? tags,
    double? sleepHours,
    bool clearSleepHours = false,
    EnergyLevel? energy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MoodEntry(
      id: id ?? this.id,
      occurredAt: occurredAt ?? this.occurredAt,
      mood: mood ?? this.mood,
      intensity: intensity ?? this.intensity,
      note: note ?? this.note,
      tags: tags ?? this.tags,
      sleepHours: clearSleepHours ? null : (sleepHours ?? this.sleepHours),
      energy: energy ?? this.energy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MoodEntry && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
