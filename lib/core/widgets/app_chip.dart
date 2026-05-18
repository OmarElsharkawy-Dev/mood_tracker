import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.trailing,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bg = selected ? colors.primary : colors.surfaceVariant;
    final fg = selected ? colors.onPrimary : colors.onSurfaceVariant;
    return InkWell(
      borderRadius: AppRadius.pillBR,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.pillBR,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: AppTextStyles.label.copyWith(color: fg)),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.xxs),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
