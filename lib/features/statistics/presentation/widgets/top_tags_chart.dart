import 'package:flutter/material.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/top_tags_view.dart';

class TopTagsChart extends StatelessWidget {
  const TopTagsChart({super.key, required this.data});

  final TopTagsView data;

  static const double _barHeight = 14;
  static const double _labelWidth = 80;
  static const double _countWidth = 28;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    if (data.entries.isEmpty) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            l10n.insightsChartEmpty,
            style: AppTextStyles.body
                .copyWith(color: colors.onSurfaceVariant),
          ),
        ),
      );
    }
    final maxCount = data.entries
        .map((e) => e.count)
        .fold<int>(0, (a, b) => a > b ? a : b)
        .clamp(1, 1 << 30);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in data.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                SizedBox(
                  width: _labelWidth,
                  child: Text(
                    entry.tag.label,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: colors.onSurface),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: SizedBox(
                    height: _barHeight,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: colors.surfaceVariant,
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: entry.count / maxCount,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                SizedBox(
                  width: _countWidth,
                  child: Text(
                    '${entry.count}',
                    textAlign: TextAlign.right,
                    style: AppTextStyles.caption
                        .copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
