import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';
import 'package:mood_tracker/features/search/domain/entry_filter.dart';

void main() {
  test('empty filter has no active dimensions', () {
    expect(EntryFilter.empty.isActive, isFalse);
    expect(EntryFilter.empty.activeCount, 0);
  });

  test('text-only filter is active with count 1', () {
    const f = EntryFilter(text: 'hike');
    expect(f.isActive, isTrue);
    expect(f.activeCount, 1);
  });

  test('empty-string text is not active', () {
    const f = EntryFilter(text: '');
    expect(f.isActive, isFalse);
    expect(f.activeCount, 0);
  });

  test('multi-dimension filter increments activeCount', () {
    const f = EntryFilter(
      text: 'note',
      moodRange: (min: Mood.bad, max: Mood.good),
      tagIds: ['t1'],
    );
    expect(f.activeCount, 3);
  });

  test('toEntryQuery passes fields through (tagIds becomes null when empty)', () {
    const f = EntryFilter(text: 'x', tagIds: []);
    final q = f.toEntryQuery();
    expect(q.text, 'x');
    expect(q.tagIds, isNull);
  });

  test('toEntryQuery preserves non-empty tagIds', () {
    const f = EntryFilter(tagIds: ['a', 'b']);
    expect(f.toEntryQuery().tagIds, ['a', 'b']);
  });

  test('copyWith updates one dimension at a time', () {
    const a = EntryFilter(text: 'one');
    final b = a.copyWith(text: 'two');
    expect(b.text, 'two');
    final c = b.copyWith(text: null);
    expect(c.text, isNull);
  });

  test('equality is value-based', () {
    const a = EntryFilter(text: 'x', tagIds: ['t1']);
    const b = EntryFilter(text: 'x', tagIds: ['t1']);
    expect(a, b);
  });
}
