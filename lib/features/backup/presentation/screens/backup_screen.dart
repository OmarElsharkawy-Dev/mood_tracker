import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../providers/backup_controller.dart';
import '../widgets/import_mode_dialog.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final state = ref.watch(backupControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(l10n.backupSubtitle),
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            icon: const Icon(Icons.upload_file),
            label: Text(l10n.backupExportButton),
            onPressed: state is BackupStateWorking
                ? null
                : () => ref.read(backupControllerProvider.notifier).export(),
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            icon: const Icon(Icons.download_for_offline_outlined),
            label: Text(l10n.backupImportButton),
            onPressed: state is BackupStateWorking
                ? null
                : () async {
                    final mode = await ImportModeDialog.show(context);
                    if (mode == null) return;
                    await ref
                        .read(backupControllerProvider.notifier)
                        .import(mode);
                  },
          ),
          const SizedBox(height: AppSpacing.lg),
          _StatusBanner(state: state),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.state});

  final BackupState state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (state) {
      BackupStateIdle() => const SizedBox.shrink(),
      BackupStateWorking() => Row(
          children: [
            const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.backupWorking),
          ],
        ),
      BackupStateSuccessExport(:final filename) =>
        Text(l10n.backupExportSuccess(filename)),
      BackupStateSuccessImport(:final count) =>
        Text(l10n.backupImportSuccess(count)),
      BackupStateError(:final failure) => ErrorView(failure: failure),
    };
  }
}
