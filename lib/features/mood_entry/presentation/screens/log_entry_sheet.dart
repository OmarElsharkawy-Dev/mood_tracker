import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/error_view.dart';
import '../../providers/log_entry_controller.dart';
import '../widgets/energy_segmented.dart';
import '../widgets/intensity_slider.dart';
import '../widgets/mood_picker_row.dart';
import '../widgets/tag_chip_input.dart';

class LogEntrySheet extends ConsumerWidget {
  const LogEntrySheet({super.key, this.editEntryId});

  final String? editEntryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final asyncState = ref.watch(logEntryControllerProvider(editEntryId));
    final controller =
        ref.read(logEntryControllerProvider(editEntryId).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.logEntryTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          failure: e is Failure ? e : UnknownFailure(cause: e),
          onRetry: () => ref.invalidate(logEntryControllerProvider(editEntryId)),
        ),
        data: (form) => SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MoodPickerRow(
                selected: form.mood,
                onSelect: controller.selectMood,
              ),
              const SizedBox(height: AppSpacing.lg),
              IntensitySlider(value: form.intensity, onChanged: controller.setIntensity),
              const SizedBox(height: AppSpacing.lg),
              EnergySegmented(value: form.energy, onChanged: controller.setEnergy),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                decoration: InputDecoration(labelText: l10n.logEntryFieldSleepHours),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (raw) => controller.setSleepHours(double.tryParse(raw)),
              ),
              const SizedBox(height: AppSpacing.lg),
              TagChipInput(tags: form.tags, onChanged: controller.setTags),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                decoration: InputDecoration(labelText: l10n.logEntryFieldNote),
                minLines: 3,
                maxLines: 6,
                onChanged: controller.setNote,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: form.canSubmit
                    ? () async {
                        final ok = await controller.submit();
                        if (ok && context.mounted) context.pop();
                      }
                    : null,
                child: Text(l10n.logEntrySave, style: AppTextStyles.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
