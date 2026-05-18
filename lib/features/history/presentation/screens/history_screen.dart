import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../mood_entry/data/mood_entry_repository_provider.dart';
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
    final colors = context.appColors;
    final async = ref.watch(historyProvider);
    final filter = ref.watch(entryFilterProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.historyTitle,
          style:
              AppTextStyles.headline.copyWith(color: colors.onBackground),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            color: colors.onSurface,
            tooltip: l10n.historySearchTooltip,
            onPressed: () => FilterSheet.show(context),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              child: _SearchBar(),
            ),
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
                      return Dismissible(
                        key: ValueKey('history_${e.id}'),
                        direction: DismissDirection.endToStart,
                        background: _DismissBackground(),
                        onDismissed: (_) =>
                            _handleDismiss(context, ref, e, l10n),
                        child: HistoryRow(
                          entry: e,
                          onTap: () =>
                              context.push(AppRoutes.entryDetailFor(e.id)),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDismiss(
    BuildContext context,
    WidgetRef ref,
    MoodEntry entry,
    dynamic l10n,
  ) async {
    final repo = ref.read(moodEntryRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    await repo.delete(entry.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.historyDelete),
        action: SnackBarAction(
          label: l10n.historyDeleteUndo,
          onPressed: () => repo.create(entry),
        ),
      ),
    );
  }
}

class _SearchBar extends ConsumerStatefulWidget {
  const _SearchBar();

  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  late final TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    final initial = ref.read(entryFilterProvider).text ?? '';
    _controller = TextEditingController(text: initial);
    _hasText = initial.isNotEmpty;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final hasText = value.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
    ref
        .read(entryFilterProvider.notifier)
        .setText(value.isEmpty ? null : value);
  }

  void _clear() {
    _controller.clear();
    setState(() => _hasText = false);
    ref.read(entryFilterProvider.notifier).setText(null);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    // Sync controller text if filter is cleared externally (e.g., via banner).
    ref.listen<dynamic>(entryFilterProvider, (prev, next) {
      final nextText = next.text ?? '';
      if (_controller.text != nextText) {
        _controller.text = nextText;
        if (nextText.isEmpty != !_hasText) {
          setState(() => _hasText = nextText.isNotEmpty);
        }
      }
    });
    return TextField(
      controller: _controller,
      style: AppTextStyles.body.copyWith(color: colors.onSurface),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        filled: true,
        fillColor: colors.surfaceVariant,
        hintText: l10n.filterTextHint,
        hintStyle:
            AppTextStyles.body.copyWith(color: colors.onSurfaceVariant),
        prefixIcon: Icon(Icons.search, color: colors.onSurfaceVariant),
        suffixIcon: _hasText
            ? IconButton(
                icon: Icon(Icons.close, color: colors.onSurfaceVariant),
                onPressed: _clear,
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      onChanged: _onChanged,
    );
  }
}

class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.error,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Icon(Icons.delete_outline, color: colors.onError),
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
