import 'package:flutter/foundation.dart';

import '../../mood_entry/domain/entities/mood_entry.dart';

@immutable
class BackupEnvelope {
  const BackupEnvelope({
    required this.schema,
    required this.exportedAt,
    required this.appVersion,
    required this.entries,
  });

  final int schema;
  final DateTime exportedAt;
  final String appVersion;
  final List<MoodEntry> entries;

  static const int currentSchema = 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BackupEnvelope &&
          schema == other.schema &&
          exportedAt == other.exportedAt &&
          appVersion == other.appVersion &&
          listEquals(entries, other.entries);

  @override
  int get hashCode =>
      Object.hash(schema, exportedAt, appVersion, Object.hashAll(entries));
}
