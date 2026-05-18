import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/error_view.dart';
import '../../domain/enums/mood.dart';
import '../../providers/log_entry_controller.dart';
import '../../providers/log_entry_form_state.dart';
import '../widgets/energy_segmented.dart';
import '../widgets/intensity_slider.dart';
import '../widgets/mood_picker_row.dart';
import '../widgets/tag_chip_input.dart';

class LogEntrySheet extends ConsumerWidget {
  const LogEntrySheet({super.key, this.editEntryId, this.initialMood});

  final String? editEntryId;
  final Mood? initialMood;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final args = (editEntryId: editEntryId, initialMood: initialMood);
    final asyncState = ref.watch(logEntryControllerProvider(args));
    final controller = ref.read(logEntryControllerProvider(args).notifier);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        top: false,
        child: DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppRadius.lg),
                ),
              ),
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: asyncState.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: ErrorView(
                      failure: e is Failure ? e : UnknownFailure(cause: e),
                      onRetry: () =>
                          ref.invalidate(logEntryControllerProvider(args)),
                    ),
                  ),
                  data: (form) => _SheetBody(
                    form: form,
                    controller: controller,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SheetBody extends StatelessWidget {
  const _SheetBody({required this.form, required this.controller});

  final LogEntryFormState form;
  final LogEntryController controller;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.outline,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close),
              color: colors.onSurface,
              onPressed: () => context.pop(),
              tooltip: l10n.logEntryCancel,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.logEntryTitle,
                style: AppTextStyles.headline.copyWith(color: colors.onSurface),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        MoodPickerRow(
          selected: form.mood,
          onSelect: controller.selectMood,
        ),
        const SizedBox(height: AppSpacing.lg),
        IntensitySlider(
          value: form.intensity,
          mood: form.mood,
          onChanged: controller.setIntensity,
        ),
        const SizedBox(height: AppSpacing.lg),
        EnergySegmented(
          value: form.energy,
          onChanged: controller.setEnergy,
        ),
        const SizedBox(height: AppSpacing.lg),
        _FilledTextField(
          hintText: l10n.logEntryFieldSleepHours,
          suffixText: l10n.logEntrySleepSuffix,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (raw) => controller.setSleepHours(double.tryParse(raw)),
        ),
        const SizedBox(height: AppSpacing.lg),
        TagChipInput(tags: form.tags, onChanged: controller.setTags),
        const SizedBox(height: AppSpacing.lg),
        _FilledTextField(
          hintText: l10n.logEntryNoteHint,
          minLines: 3,
          maxLines: 8,
          onChanged: controller.setNote,
        ),
        const SizedBox(height: AppSpacing.xl),
        _SaveButton(
          enabled: form.canSubmit,
          label: l10n.logEntrySave,
          onPressed: () async {
            final ok = await controller.submit();
            if (ok && context.mounted) context.pop();
          },
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _FilledTextField extends StatelessWidget {
  const _FilledTextField({
    required this.hintText,
    required this.onChanged,
    this.suffixText,
    this.keyboardType,
    this.minLines,
    this.maxLines = 1,
  });

  final String hintText;
  final ValueChanged<String> onChanged;
  final String? suffixText;
  final TextInputType? keyboardType;
  final int? minLines;
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hintStyle =
        AppTextStyles.body.copyWith(color: colors.onSurfaceVariant);
    return TextField(
      keyboardType: keyboardType,
      minLines: minLines,
      maxLines: maxLines,
      style: AppTextStyles.body.copyWith(color: colors.onSurface),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: hintStyle,
        suffixText: suffixText,
        suffixStyle: hintStyle,
        filled: true,
        fillColor: colors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
      ),
      onChanged: onChanged,
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: colors.outline,
          disabledForegroundColor: colors.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        onPressed: enabled ? onPressed : null,
        child: Text(
          label,
          style: AppTextStyles.label
              .copyWith(color: enabled ? colors.onPrimary : colors.onSurfaceVariant),
        ),
      ),
    );
  }
}
