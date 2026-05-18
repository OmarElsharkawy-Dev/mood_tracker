import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class PermissionDeniedCard extends StatelessWidget {
  const PermissionDeniedCard({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    return Card(
      margin: const EdgeInsets.all(AppSpacing.md),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBR),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.remindersPermissionDeniedTitle, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.remindersPermissionDeniedBody,
              style: AppTextStyles.body.copyWith(color: colors.onMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onOpenSettings,
                child: Text(l10n.remindersOpenSettings),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
