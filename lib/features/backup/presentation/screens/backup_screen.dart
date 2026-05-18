import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/error_view.dart';
import '../../providers/backup_controller.dart';
import '../widgets/import_mode_dialog.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final state = ref.watch(backupControllerProvider);
    final busy = state is BackupStateWorking;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.backupTitle,
          style:
              AppTextStyles.headline.copyWith(color: colors.onBackground),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text(
            l10n.backupSubtitle,
            style: AppTextStyles.body.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.lg),
          _PrimaryButton(
            label: l10n.backupExportButton,
            icon: Icons.upload_file,
            onPressed: busy
                ? null
                : () =>
                    ref.read(backupControllerProvider.notifier).export(),
          ),
          const SizedBox(height: AppSpacing.sm),
          _OutlinedButton(
            label: l10n.backupImportButton,
            icon: Icons.download_for_offline_outlined,
            onPressed: busy
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

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        icon: Icon(icon),
        label: Text(
          label,
          style: AppTextStyles.label.copyWith(color: colors.onPrimary),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          disabledBackgroundColor: colors.outline,
          disabledForegroundColor: colors.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}

class _OutlinedButton extends StatelessWidget {
  const _OutlinedButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        icon: Icon(icon, color: colors.primary),
        label: Text(
          label,
          style: AppTextStyles.label.copyWith(color: colors.primary),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
        ),
        onPressed: onPressed,
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
    final colors = context.appColors;
    final captionStyle = AppTextStyles.bodySmall.copyWith(
      color: colors.onSurfaceVariant,
    );
    return switch (state) {
      BackupStateIdle() => const SizedBox.shrink(),
      BackupStateWorking() => Row(
          children: [
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(l10n.backupWorking, style: captionStyle),
          ],
        ),
      BackupStateSuccessExport(:final filename) =>
        Text(l10n.backupExportSuccess(filename), style: captionStyle),
      BackupStateSuccessImport(:final count) =>
        Text(l10n.backupImportSuccess(count), style: captionStyle),
      BackupStateError(:final failure) => ErrorView(failure: failure),
    };
  }
}
