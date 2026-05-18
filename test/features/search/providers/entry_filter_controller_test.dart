import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/search/domain/entry_filter.dart';
import 'package:mood_tracker/features/search/providers/entry_filter_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });
  tearDown(() => container.dispose());

  test('initial state is empty filter', () {
    expect(container.read(entryFilterProvider), EntryFilter.empty);
  });

  test('setText normalizes empty string to null', () {
    final n = container.read(entryFilterProvider.notifier);
    n.setText('');
    expect(container.read(entryFilterProvider).text, isNull);
    expect(container.read(entryFilterProvider).isActive, isFalse);
  });

  test('setText sets non-empty value', () {
    final n = container.read(entryFilterProvider.notifier);
    n.setText('hike');
    expect(container.read(entryFilterProvider).text, 'hike');
    expect(container.read(entryFilterProvider).isActive, isTrue);
  });

  test('setMoodRange/setDateRange/setTagIds update the filter', () {
    final n = container.read(entryFilterProvider.notifier);
    n.setMoodRange((min: Mood.bad, max: Mood.good));
    n.setTagIds(['t1', 't2']);
    final f = container.read(entryFilterProvider);
    expect(f.moodRange, (min: Mood.bad, max: Mood.good));
    expect(f.tagIds, ['t1', 't2']);
  });

  test('clear resets to empty', () {
    final n = container.read(entryFilterProvider.notifier);
    n.setText('x');
    n.setTagIds(['t1']);
    n.clear();
    expect(container.read(entryFilterProvider), EntryFilter.empty);
  });

  test('replace overwrites the whole filter', () {
    final n = container.read(entryFilterProvider.notifier);
    n.setText('first');
    n.replace(const EntryFilter(text: 'second'));
    expect(container.read(entryFilterProvider).text, 'second');
  });
}
