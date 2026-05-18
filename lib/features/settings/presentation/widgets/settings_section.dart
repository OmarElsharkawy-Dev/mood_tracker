import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_divider.dart';

class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.lg),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.label.copyWith(color: colors.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const AppDivider(),
          children[i],
        ],
      ],
    );
  }
}
