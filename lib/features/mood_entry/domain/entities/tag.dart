import 'package:flutter/foundation.dart';

@immutable
class Tag {
  const Tag({required this.id, required this.slug, required this.label});

  final String id;
  final String slug;
  final String label;

  static final _slugAllowed = RegExp(r'[^a-z0-9-]');

  static String slugify(String raw) {
    final trimmed = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '-');
    return trimmed.replaceAll(_slugAllowed, '');
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Tag && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
