import 'package:flutter/foundation.dart' show visibleForTesting;

import '../../mood_entry/domain/entities/mood_entry.dart';
import '../../mood_entry/domain/entities/tag.dart';
import '../../mood_entry/domain/enums/energy_level.dart';
import '../../mood_entry/domain/enums/mood.dart';
import '../domain/backup_envelope.dart';

class BackupFormatException implements Exception {
  const BackupFormatException(this.messageKey, {this.index});

  final String messageKey;
  final int? index;

  @override
  String toString() => 'BackupFormatException($messageKey, index=$index)';
}

Map<String, dynamic> envelopeToJson(BackupEnvelope env) {
  return {
    'schema': env.schema,
    'exportedAt': env.exportedAt.toUtc().toIso8601String(),
    'appVersion': env.appVersion,
    'entries': env.entries.map(_entryToJson).toList(),
  };
}

BackupEnvelope envelopeFromJson(Map<String, dynamic> raw) {
  final migrated = migrate(Map<String, dynamic>.from(raw));
  try {
    final entriesRaw = (migrated['entries'] as List).cast<dynamic>();
    final entries = <MoodEntry>[];
    for (var i = 0; i < entriesRaw.length; i++) {
      try {
        entries.add(_entryFromJson(entriesRaw[i] as Map<String, dynamic>));
      } catch (_) {
        throw BackupFormatException('backupErrorParseFailed', index: i);
      }
    }
    return BackupEnvelope(
      schema: migrated['schema'] as int,
      exportedAt: DateTime.parse(migrated['exportedAt'] as String),
      appVersion: migrated['appVersion'] as String,
      entries: entries,
    );
  } on BackupFormatException {
    rethrow;
  } catch (_) {
    throw const BackupFormatException('backupErrorParseFailed');
  }
}

@visibleForTesting
Map<String, dynamic> migrate(Map<String, dynamic> raw) {
  final schema = raw['schema'] as int? ?? 0;
  if (schema >= BackupEnvelope.currentSchema) return raw;
  return {...raw, 'schema': BackupEnvelope.currentSchema};
}

Map<String, dynamic> _entryToJson(MoodEntry e) {
  return {
    'id': e.id,
    'occurredAt': e.occurredAt.millisecondsSinceEpoch,
    'mood': e.mood.name,
    'intensity': e.intensity,
    'note': e.note,
    'tags': e.tags.map((t) => t.slug).toList(),
    'sleepHours': e.sleepHours,
    'energy': e.energy.name,
    'createdAt': e.createdAt.millisecondsSinceEpoch,
    'updatedAt': e.updatedAt.millisecondsSinceEpoch,
  };
}

MoodEntry _entryFromJson(Map<String, dynamic> raw) {
  final moodName = raw['mood'] as String;
  final mood = Mood.values.firstWhere(
    (m) => m.name == moodName,
    orElse: () => throw const FormatException('bad mood'),
  );
  final energyName = raw['energy'] as String;
  final energy = EnergyLevel.values.firstWhere(
    (e) => e.name == energyName,
    orElse: () => throw const FormatException('bad energy'),
  );
  final tagsRaw = (raw['tags'] as List).cast<String>();
  return MoodEntry(
    id: raw['id'] as String,
    occurredAt: DateTime.fromMillisecondsSinceEpoch(raw['occurredAt'] as int),
    mood: mood,
    intensity: raw['intensity'] as int,
    note: raw['note'] as String?,
    tags: [
      for (final slug in tagsRaw)
        Tag(id: 't_$slug', slug: slug, label: _titleCase(slug)),
    ],
    sleepHours: (raw['sleepHours'] as num?)?.toDouble(),
    energy: energy,
    createdAt: DateTime.fromMillisecondsSinceEpoch(raw['createdAt'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(raw['updatedAt'] as int),
  );
}

String _titleCase(String slug) {
  if (slug.isEmpty) return slug;
  return slug
      .split('_')
      .map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1))
      .join(' ');
}
