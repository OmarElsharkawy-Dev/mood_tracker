import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/mood_dot.dart';
import '../../../mood_entry/data/mood_entry_repository_provider.dart';
import '../../../mood_entry/domain/entities/mood_entry.dart';
import '../../../mood_entry/domain/enums/mood.dart';

final entryByIdProvider =
    FutureProvider.autoDispose.family<MoodEntry, String>((ref, id) async {
  final (entry, err) = await ref.watch(moodEntryRepositoryProvider).getById(id);
  if (entry == null) throw err!;
  return entry;
});

class EntryDetailScreen extends ConsumerWidget {
  const EntryDetailScreen({super.key, required this.entryId});
  final String entryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(entryByIdProvider(entryId));
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.entryDetailTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => context.push(AppRoutes.entryEditFor(entryId)),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final (_, err) = await ref
                  .read(moodEntryRepositoryProvider)
                  .delete(entryId);
              if (err == null && context.mounted) context.pop();
            },
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            ErrorView(failure: e is Failure ? e : const UnknownFailure(cause: 'unknown')),
        data: (entry) {
          final colors = context.appColors;
          final fmt = DateFormat.yMMMMd().add_jm();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    MoodDot(mood: entry.mood, size: 18),
                    const SizedBox(width: AppSpacing.xs),
                    Text(_moodLabel(context, entry.mood),
                        style: AppTextStyles.headline),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(fmt.format(entry.occurredAt),
                    style: AppTextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant)),
                const SizedBox(height: AppSpacing.lg),
                if ((entry.note ?? '').isNotEmpty)
                  Text(entry.note!, style: AppTextStyles.body),
              ],
            ),
          );
        },
      ),
    );
  }

  String _moodLabel(BuildContext context, Mood mood) {
    final l10n = context.l10n;
    return switch (mood) {
      Mood.awful => l10n.moodAwful,
      Mood.bad => l10n.moodBad,
      Mood.okay => l10n.moodOkay,
      Mood.good => l10n.moodGood,
      Mood.great => l10n.moodGreat,
    };
  }
}
