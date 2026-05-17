import '../../../../core/error/failure.dart';
import '../../../../core/error/result.dart';
import '../entities/mood_entry.dart';
import 'entry_query.dart';

abstract class MoodEntryRepository {
  Future<(MoodEntry?, Failure?)> create(MoodEntry entry);
  Future<(MoodEntry?, Failure?)> update(MoodEntry entry);
  Future<(Unit?, Failure?)> delete(String id);
  Future<(MoodEntry?, Failure?)> getById(String id);
  Stream<List<MoodEntry>> watchAll({EntryQuery? query});
  Future<(List<MoodEntry>?, Failure?)> getAll({EntryQuery? query});
}
