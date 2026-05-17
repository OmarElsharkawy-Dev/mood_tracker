import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/mood_entry/domain/entities/tag.dart';

void main() {
  group('Tag', () {
    test('slugify lowercases and trims and replaces spaces', () {
      expect(Tag.slugify('  Bad Sleep '), 'bad-sleep');
    });

    test('slugify drops non-alphanumeric except dash', () {
      expect(Tag.slugify('café!'), 'caf');
    });

    test('equality is by id', () {
      const a = Tag(id: '1', slug: 'work', label: 'Work');
      const b = Tag(id: '1', slug: 'WORK', label: 'work');
      expect(a, b);
    });
  });
}
