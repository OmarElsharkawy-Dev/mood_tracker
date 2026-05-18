import '../../../l10n/app_localizations.dart';
import '../../mood_entry/domain/enums/mood.dart';
import 'correlation.dart';
import 'mood_distribution.dart';
import 'mood_trend.dart';
import 'top_tags_view.dart';

String _fmt(double v) => v.toStringAsFixed(1);

String labelForBucketKey(String key, AppLocalizations l) {
  switch (key) {
    case 'insightsSleepBucketUnder6':
      return l.insightsSleepBucketUnder6;
    case 'insightsSleepBucket6to7':
      return l.insightsSleepBucket6to7;
    case 'insightsSleepBucket7to8':
      return l.insightsSleepBucket7to8;
    case 'insightsSleepBucket8to9':
      return l.insightsSleepBucket8to9;
    case 'insightsSleepBucket9plus':
      return l.insightsSleepBucket9plus;
    case 'energyVeryLow':
      return l.energyVeryLow;
    case 'energyLow':
      return l.energyLow;
    case 'energyMedium':
      return l.energyMedium;
    case 'energyHigh':
      return l.energyHigh;
    case 'energyVeryHigh':
      return l.energyVeryHigh;
  }
  return key;
}

String trendSummary(MoodTrendSeries series, AppLocalizations l) {
  final avg = series.overallAverage ?? 0;
  final min = series.minDay ?? 0;
  final max = series.maxDay ?? 0;
  return l.a11yTrendSummary(series.daysWithData, _fmt(avg), _fmt(min), _fmt(max));
}

String distributionSummary(MoodDistribution d, AppLocalizations l) {
  return l.a11yDistributionSummary(
    d.counts[Mood.great]!,
    d.counts[Mood.good]!,
    d.counts[Mood.okay]!,
    d.counts[Mood.bad]!,
    d.counts[Mood.awful]!,
  );
}

String topTagsSummary(TopTagsView v, AppLocalizations l) {
  final summary = v.entries.map((e) => '${e.tag.label} ${e.count}').join(', ');
  return l.a11yTopTagsSummary(summary);
}

String sleepSummary(CorrelationView v, AppLocalizations l) {
  final parts = <String>[];
  for (final b in v.buckets) {
    if (b.averageMood == null) continue;
    final label = labelForBucketKey(b.bucketLabelKey, l);
    parts.add('$label ${_avgWord(l)} ${_fmt(b.averageMood!)}');
  }
  return l.a11ySleepSummary(parts.join(', '));
}

String energySummary(CorrelationView v, AppLocalizations l) {
  final parts = <String>[];
  for (final b in v.buckets) {
    if (b.averageMood == null) continue;
    final label = labelForBucketKey(b.bucketLabelKey, l);
    parts.add('$label ${_avgWord(l)} ${_fmt(b.averageMood!)}');
  }
  return l.a11yEnergySummary(parts.join(', '));
}

// Locale heuristic: if a future locale needs a different word, add a dedicated
// ARB key. For Phase 4 (EN + ES only) this startsWith check is sufficient.
String _avgWord(AppLocalizations l) =>
    l.localeName.startsWith('es') ? 'prom.' : 'avg';
