import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/infrastructure_providers.dart';
import '../domain/repositories/mood_entry_repository.dart';
import 'mood_entry_repository_impl.dart';

final moodEntryRepositoryProvider = Provider<MoodEntryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return MoodEntryRepositoryImpl(db);
});
