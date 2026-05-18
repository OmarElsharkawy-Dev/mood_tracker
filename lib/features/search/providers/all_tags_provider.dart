import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mood_entry/data/mood_entry_repository_provider.dart';
import '../../mood_entry/domain/entities/tag.dart';

final allTagsProvider = StreamProvider<List<Tag>>((ref) {
  final repo = ref.watch(moodEntryRepositoryProvider);
  return repo.watchAll().map((entries) {
    final byId = <String, Tag>{};
    for (final e in entries) {
      for (final t in e.tags) {
        byId[t.id] = t;
      }
    }
    final list = byId.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));
    return list;
  });
});
