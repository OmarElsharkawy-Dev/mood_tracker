import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../mood_entry/domain/entities/mood_entry.dart';
import '../../../mood_entry/domain/entities/tag.dart';
import '../../../mood_entry/domain/enums/energy_level.dart';
import '../../../mood_entry/domain/enums/mood.dart';
import '../../../search/presentation/widgets/filter_sheet.dart';
import '../../../search/providers/entry_filter_controller.dart';
import '../../providers/history_controller.dart';
import '../widgets/active_filter_banner.dart';
import '../widgets/history_row.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(historyProvider);
    final filter = ref.watch(entryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.historyTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.historySearchTooltip,
            onPressed: () => FilterSheet.show(context),
          ),
        ],
      ),
      body: Column(
        children: [
          const ActiveFilterBanner(),
          Expanded(
            child: async.when(
              loading: () => Skeletonizer(
                child: ListView.builder(
                  itemCount: 8,
                  itemBuilder: (context, i) => HistoryRow(
                    entry: _skeletonEntry,
                    onTap: () {},
                  ),
                ),
              ),
              error: (e, _) => ErrorView(
                failure: e is Failure ? e : UnknownFailure(cause: e),
              ),
              data: (entries) {
                if (entries.isEmpty) {
                  if (filter.isActive) {
                    return EmptyStateView(
                      title: l10n.historyNoMatchesTitle,
                      message: l10n.historyNoMatchesMessage,
                      action: FilledButton(
                        onPressed: () =>
                            ref.read(entryFilterProvider.notifier).clear(),
                        child: Text(l10n.filterClear),
                      ),
                    );
                  }
                  return EmptyStateView(
                    title: l10n.historyTitle,
                    message: l10n.historyEmpty,
                  );
                }
                return ListView.builder(
                  itemCount: entries.length,
                  itemBuilder: (_, i) {
                    final e = entries[i];
                    return HistoryRow(
                      entry: e,
                      onTap: () => context.push(AppRoutes.entryDetailFor(e.id)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

final _skeletonEntry = MoodEntry(
  id: 'skel',
  occurredAt: DateTime(2026, 5, 17),
  mood: Mood.okay,
  intensity: 5,
  note: 'placeholder text',
  tags: const <Tag>[],
  sleepHours: null,
  energy: EnergyLevel.medium,
  createdAt: DateTime(2026, 5, 17),
  updatedAt: DateTime(2026, 5, 17),
);
