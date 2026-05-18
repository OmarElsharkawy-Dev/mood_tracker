import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/mood_dot.dart';
import '../../../mood_entry/domain/entities/mood_entry.dart';

class HistoryRow extends StatelessWidget {
  const HistoryRow({super.key, required this.entry, required this.onTap});

  final MoodEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fmt = DateFormat.MMMd().add_jm();
    return ListTile(
      leading: MoodDot(mood: entry.mood, size: 14),
      title: Text(fmt.format(entry.occurredAt), style: AppTextStyles.body),
      subtitle: Text(
        entry.note ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTextStyles.bodySmall.copyWith(color: colors.onSurfaceVariant),
      ),
      onTap: onTap,
    );
  }
}
