import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mood_entry/data/mood_entry_repository_provider.dart';
import '../../mood_entry/domain/entities/mood_entry.dart';

/// Top 3 most-recent entries for the Today screen.
final recentEntriesProvider = StreamProvider<List<MoodEntry>>((ref) {
  final repo = ref.watch(moodEntryRepositoryProvider);
  return repo.watchAll().map((all) => all.take(3).toList());
});

String greetingFor(DateTime now) {
  final h = now.hour;
  if (h < 12) return 'morning';
  if (h < 18) return 'afternoon';
  return 'evening';
}
