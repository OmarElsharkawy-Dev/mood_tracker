import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/uuid.dart';
import '../data/mood_entry_repository_provider.dart';
import '../domain/entities/tag.dart';
import '../domain/enums/energy_level.dart';
import '../domain/enums/mood.dart';
import '../domain/repositories/mood_entry_repository.dart';
import 'log_entry_form_state.dart';

typedef LogEntryArgs = ({String? editEntryId, Mood? initialMood});

class LogEntryController
    extends AutoDisposeFamilyAsyncNotifier<LogEntryFormState, LogEntryArgs> {
  late MoodEntryRepository _repo;
  late String _entryId;

  @override
  Future<LogEntryFormState> build(LogEntryArgs args) async {
    _repo = ref.watch(moodEntryRepositoryProvider);
    final now = DateTime.now();
    final editId = args.editEntryId;
    if (editId == null) {
      _entryId = generateId();
      final blank = LogEntryFormState.blank(now);
      final initial = args.initialMood;
      return initial == null ? blank : blank.copyWith(mood: initial);
    }
    _entryId = editId;
    final (entry, err) = await _repo.getById(editId);
    if (entry == null) throw err!;
    return LogEntryFormState(
      occurredAt: entry.occurredAt,
      mood: entry.mood,
      intensity: entry.intensity,
      energy: entry.energy,
      note: entry.note ?? '',
      tags: entry.tags,
      sleepHours: entry.sleepHours,
    );
  }

  void selectMood(Mood mood) => _patch((s) => s.copyWith(mood: mood));
  void setIntensity(int v) => _patch((s) => s.copyWith(intensity: v));
  void setEnergy(EnergyLevel v) => _patch((s) => s.copyWith(energy: v));
  void setNote(String v) => _patch((s) => s.copyWith(note: v));
  void setSleepHours(double? v) => _patch(
      (s) => s.copyWith(sleepHours: v, clearSleepHours: v == null));
  void setOccurredAt(DateTime v) => _patch((s) => s.copyWith(occurredAt: v));
  void setTags(List<Tag> v) => _patch((s) => s.copyWith(tags: v));

  void _patch(LogEntryFormState Function(LogEntryFormState) f) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(f(current));
  }

  Future<bool> submit() async {
    final s = state.value;
    if (s == null || !s.canSubmit) return false;
    final now = DateTime.now();
    final entity = s.toEntity(id: _entryId, now: now)!;
    final (_, err) = arg.editEntryId == null
        ? await _repo.create(entity)
        : await _repo.update(entity);
    return err == null;
  }
}

final logEntryControllerProvider = AsyncNotifierProvider.autoDispose
    .family<LogEntryController, LogEntryFormState, LogEntryArgs>(
  LogEntryController.new,
);
