import 'package:flutter/foundation.dart';

@immutable
sealed class Failure {
  const Failure({this.debugMessage});

  final String? debugMessage;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          debugMessage == other.debugMessage;

  @override
  int get hashCode => Object.hash(runtimeType, debugMessage);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure({super.debugMessage});
}

class NotFoundFailure extends Failure {
  const NotFoundFailure({required this.id, super.debugMessage});

  final String id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotFoundFailure && super == other && id == other.id;

  @override
  int get hashCode => Object.hash(super.hashCode, id);
}

class ValidationFailure extends Failure {
  const ValidationFailure({required this.fieldErrors, super.debugMessage});

  final Map<String, String> fieldErrors;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationFailure &&
          super == other &&
          mapEquals(fieldErrors, other.fieldErrors);

  @override
  int get hashCode => Object.hash(super.hashCode, fieldErrors);
}

class IOFailure extends Failure {
  const IOFailure({super.debugMessage});
}

class UnknownFailure extends Failure {
  const UnknownFailure({required this.cause, super.debugMessage});

  final Object cause;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnknownFailure && super == other && cause == other.cause;

  @override
  int get hashCode => Object.hash(super.hashCode, cause);
}
