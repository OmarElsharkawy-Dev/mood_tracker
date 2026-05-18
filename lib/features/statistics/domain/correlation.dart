import 'package:flutter/foundation.dart';

enum SleepBucket { under6, h6to7, h7to8, h8to9, h9plus }

extension SleepBucketX on SleepBucket {
  String get labelKey {
    switch (this) {
      case SleepBucket.under6:
        return 'insightsSleepBucketUnder6';
      case SleepBucket.h6to7:
        return 'insightsSleepBucket6to7';
      case SleepBucket.h7to8:
        return 'insightsSleepBucket7to8';
      case SleepBucket.h8to9:
        return 'insightsSleepBucket8to9';
      case SleepBucket.h9plus:
        return 'insightsSleepBucket9plus';
    }
  }
}

SleepBucket sleepBucketFor(double hours) {
  if (hours < 6) return SleepBucket.under6;
  if (hours < 7) return SleepBucket.h6to7;
  if (hours < 8) return SleepBucket.h7to8;
  if (hours < 9) return SleepBucket.h8to9;
  return SleepBucket.h9plus;
}

@immutable
class CorrelationBucket {
  const CorrelationBucket({
    required this.bucketLabelKey,
    required this.sampleSize,
    required this.averageMood,
  });

  final String bucketLabelKey;
  final int sampleSize;
  final double? averageMood;
}

@immutable
class CorrelationView {
  const CorrelationView({required this.buckets});

  final List<CorrelationBucket> buckets;

  int get nonEmptyBucketCount =>
      buckets.where((b) => b.sampleSize > 0).length;
}
