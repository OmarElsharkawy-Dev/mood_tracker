import '../../../../core/db/app_database.dart';
import '../../domain/entities/mood_entry.dart';
import '../../domain/entities/tag.dart';
import '../../domain/enums/energy_level.dart';
import '../../domain/enums/mood.dart';

MoodEntry rowToEntity(EntryRow row, {required List<Tag> tags}) {
  return MoodEntry(
    id: row.id,
    occurredAt: DateTime.fromMillisecondsSinceEpoch(row.occurredAt),
    mood: Mood.values[row.mood],
    intensity: row.intensity,
    note: row.note,
    tags: tags,
    sleepHours: row.sleepHours,
    energy: EnergyLevel.values[row.energy],
    createdAt: DateTime.fromMillisecondsSinceEpoch(row.createdAt),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(row.updatedAt),
  );
}

EntryRow entityToRow(MoodEntry entity) {
  return EntryRow(
    id: entity.id,
    occurredAt: entity.occurredAt.millisecondsSinceEpoch,
    mood: entity.mood.index,
    intensity: entity.intensity,
    note: entity.note,
    sleepHours: entity.sleepHours,
    energy: entity.energy.index,
    createdAt: entity.createdAt.millisecondsSinceEpoch,
    updatedAt: entity.updatedAt.millisecondsSinceEpoch,
  );
}

Tag rowToTag(TagRow row) =>
    Tag(id: row.id, slug: row.slug, label: row.label);

TagRow tagToRow(Tag tag) =>
    TagRow(id: tag.id, slug: tag.slug, label: tag.label);
