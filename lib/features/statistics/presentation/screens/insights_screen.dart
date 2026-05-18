import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../history/presentation/widgets/active_filter_banner.dart';
import '../../../search/presentation/widgets/filter_sheet.dart';
import '../../domain/accessibility_summaries.dart';
import '../../domain/mood_distribution.dart';
import '../../providers/chart_providers.dart';
import '../widgets/energy_correlation_chart.dart';
import '../widgets/insight_section_card.dart';
import '../widgets/mood_distribution_chart.dart';
import '../widgets/mood_trend_chart.dart';
import '../widgets/range_selector.dart';
import '../widgets/sleep_correlation_chart.dart';
import '../widgets/top_tags_chart.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.insightsTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: l10n.insightsFilterTooltip,
            onPressed: () => FilterSheet.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          const RangeSelector(),
          const ActiveFilterBanner(),
          Expanded(
            child: ListView(
              children: [
                InsightSectionCard(
                  title: l10n.insightsMoodTrend,
                  value: ref.watch(moodTrendProvider),
                  isEmpty: (v) => v.daysWithData < 2,
                  emptyMessage: l10n.insightsTrendEmpty,
                  accessibilitySummary: ref.watch(moodTrendProvider).maybeWhen(
                        data: (v) => trendSummary(v, l10n),
                        orElse: () => null,
                      ),
                  builder: (v) => MoodTrendChart(series: v),
                ),
                InsightSectionCard<MoodDistribution>(
                  title: l10n.insightsDistribution,
                  value: ref.watch(moodDistributionProvider),
                  isEmpty: (v) => v.total == 0,
                  emptyMessage: l10n.insightsDistributionEmpty,
                  accessibilitySummary:
                      ref.watch(moodDistributionProvider).maybeWhen(
                            data: (v) => distributionSummary(v, l10n),
                            orElse: () => null,
                          ),
                  builder: (v) => MoodDistributionChart(data: v),
                ),
                InsightSectionCard(
                  title: l10n.insightsTopTags,
                  value: ref.watch(topTagsProvider),
                  isEmpty: (v) => v.entries.isEmpty,
                  emptyMessage: l10n.insightsTopTagsEmpty,
                  accessibilitySummary: ref.watch(topTagsProvider).maybeWhen(
                        data: (v) => topTagsSummary(v, l10n),
                        orElse: () => null,
                      ),
                  builder: (v) => TopTagsChart(data: v),
                ),
                InsightSectionCard(
                  title: l10n.insightsSleepVsMood,
                  value: ref.watch(sleepCorrelationProvider),
                  isEmpty: (v) => v.nonEmptyBucketCount == 0,
                  emptyMessage: l10n.insightsSleepEmpty,
                  accessibilitySummary:
                      ref.watch(sleepCorrelationProvider).maybeWhen(
                            data: (v) => sleepSummary(v, l10n),
                            orElse: () => null,
                          ),
                  builder: (v) => SleepCorrelationChart(data: v),
                ),
                InsightSectionCard(
                  title: l10n.insightsEnergyVsMood,
                  value: ref.watch(energyCorrelationProvider),
                  isEmpty: (v) => v.nonEmptyBucketCount == 0,
                  emptyMessage: l10n.insightsEnergyEmpty,
                  accessibilitySummary:
                      ref.watch(energyCorrelationProvider).maybeWhen(
                            data: (v) => energySummary(v, l10n),
                            orElse: () => null,
                          ),
                  builder: (v) => EnergyCorrelationChart(data: v),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
