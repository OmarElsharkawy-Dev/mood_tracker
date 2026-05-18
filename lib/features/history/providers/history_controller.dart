import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mood_entry/data/mood_entry_repository_provider.dart';
import '../../mood_entry/domain/entities/mood_entry.dart';
import '../../search/providers/entry_filter_controller.dart';

final historyProvider = StreamProvider<List<MoodEntry>>((ref) {
  final repo = ref.watch(moodEntryRepositoryProvider);
  final filter = ref.watch(entryFilterProvider);
  return repo.watchAll(query: filter.toEntryQuery());
});
