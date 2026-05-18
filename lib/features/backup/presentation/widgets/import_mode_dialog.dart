// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../domain/import_mode.dart';

class ImportModeDialog {
  /// Shows the import-mode picker. Returns the chosen mode, or null on cancel.
  /// For Replace, also shows a secondary confirm; returns null if not confirmed.
  static Future<ImportMode?> show(BuildContext context) async {
    final selected = ValueNotifier<ImportMode>(ImportMode.merge);
    final picked = await showDialog<ImportMode>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Text(l10n.backupImportModeTitle),
          content: ValueListenableBuilder<ImportMode>(
            valueListenable: selected,
            builder: (context, value, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<ImportMode>(
                    value: ImportMode.merge,
                    groupValue: value,
                    onChanged: (v) => selected.value = v!,
                    title: Text(l10n.backupImportModeMerge),
                    subtitle: Text(l10n.backupImportModeMergeHint),
                  ),
                  RadioListTile<ImportMode>(
                    value: ImportMode.replace,
                    groupValue: value,
                    onChanged: (v) => selected.value = v!,
                    title: Text(l10n.backupImportModeReplace),
                    subtitle: Text(l10n.backupImportModeReplaceHint),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.backupImportCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(selected.value),
              child: Text(l10n.backupImportContinue),
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
          title: Text(l10n.backupReplaceConfirmTitle),
          content: Text(l10n.backupReplaceConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.backupImportCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.backupImportContinue),
            ),
          ],
        ),
      );
      if (confirmed != true) return null;
    }

    return picked;
  }
}
