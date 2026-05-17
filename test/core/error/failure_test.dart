import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/error/failure.dart';

void main() {
  group('Failure', () {
    test('DatabaseFailure carries a debug message', () {
      const failure = DatabaseFailure(debugMessage: 'db locked');
      expect(failure.debugMessage, 'db locked');
    });

    test('NotFoundFailure exposes the id that was missing', () {
      const failure = NotFoundFailure(id: 'abc-123');
      expect(failure.id, 'abc-123');
    });

    test('ValidationFailure carries field-level errors', () {
      const failure = ValidationFailure(fieldErrors: {'intensity': 'must be 1..10'});
      expect(failure.fieldErrors['intensity'], 'must be 1..10');
    });

    test('two equivalent ValidationFailures are equal', () {
      const a = ValidationFailure(fieldErrors: {'x': 'y'});
      const b = ValidationFailure(fieldErrors: {'x': 'y'});
      expect(a, b);
    });
  });
}
