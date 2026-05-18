import 'package:flutter/foundation.dart';

import '../../mood_entry/domain/entities/tag.dart';

@immutable
class TopTagEntry {
  const TopTagEntry({required this.tag, required this.count});

  final Tag tag;
  final int count;
}

@immutable
class TopTagsView {
  const TopTagsView({required this.entries, required this.totalTaggedEntries});

  final List<TopTagEntry> entries;
  final int totalTaggedEntries;
}
