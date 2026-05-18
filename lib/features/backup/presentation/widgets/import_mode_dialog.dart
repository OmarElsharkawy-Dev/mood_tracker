import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/import_mode.dart';

class ImportModeDialog {
  /// Shows the import-mode picker. Returns the chosen mode, or null on cancel.
  /// For Replace, also shows a secondary confirm; returns null if not confirmed.
  static Future<ImportMode?> show(BuildContext context) async {
    final selected = ValueNotifier<ImportMode>(ImportMode.merge);
    final colors = context.appColors;

    final picked = await showDialog<ImportMode>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: Text(
            l10n.backupImportModeTitle,
            style:
                AppTextStyles.label.copyWith(color: colors.onSurface, fontSize: 16),
          ),
          content: ValueListenableBuilder<ImportMode>(
            valueListenable: selected,
            builder: (context, value, _) {
              return RadioGroup<ImportMode>(
                groupValue: value,
                onChanged: (v) => v == null ? null : selected.value = v,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ModeRow(
                      value: ImportMode.merge,
                      title: l10n.backupImportModeMerge,
                      subtitle: l10n.backupImportModeMergeHint,
                      tint: colors.primary,
                    ),
                    _ModeRow(
                      value: ImportMode.replace,
                      title: l10n.backupImportModeReplace,
                      subtitle: l10n.backupImportModeReplaceHint,
                      tint: colors.error,
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.backupImportCancel,
                style: AppTextStyles.label
                    .copyWith(color: colors.onSurfaceVariant),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
              ),
              onPressed: () =>
                  Navigator.of(context).pop(selected.value),
              child: Text(
                l10n.backupImportContinue,
                style:
                    AppTextStyles.label.copyWith(color: colors.onPrimary),
              ),
            ),
          ],
        );
      },
    );

    if (picked == ImportMode.replace && context.mounted) {
      final l10n = context.l10n;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          title: Text(
            l10n.backupReplaceConfirmTitle,
            style: AppTextStyles.label
                .copyWith(color: colors.onSurface, fontSize: 16),
          ),
          content: Text(
            l10n.backupReplaceConfirmBody,
            style:
                AppTextStyles.body.copyWith(color: colors.onSurfaceVariant),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                l10n.backupImportCancel,
                style: AppTextStyles.label
                    .copyWith(color: colors.onSurfaceVariant),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                l10n.backupImportContinue,
                style:
                    AppTextStyles.label.copyWith(color: colors.onError),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return null;
    }

    return picked;
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow({
    required this.value,
    required this.title,
    required this.subtitle,
    required this.tint,
  });

  final ImportMode value;
  final String title;
  final String subtitle;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: () {
        RadioGroup.maybeOf<ImportMode>(context)?.onChanged(value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Radio<ImportMode>(value: value, activeColor: tint),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        AppTextStyles.label.copyWith(color: tint, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
