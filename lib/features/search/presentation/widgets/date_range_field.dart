import 'package:flutter/material.dart' hide DateTimeRange;
import 'package:flutter/material.dart' as material show DateTimeRange;
import 'package:intl/intl.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../mood_entry/domain/repositories/entry_query.dart';

class DateRangeField extends StatelessWidget {
  const DateRangeField({
    super.key,
    required this.range,
    required this.onChanged,
  });

  final DateTimeRange? range;
  final ValueChanged<DateTimeRange?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    final fmt =
        DateFormat.yMMMd(Localizations.localeOf(context).languageCode);
    final hasRange = range != null;
    final label = hasRange
        ? '${fmt.format(range!.start)} – ${fmt.format(range!.end)}'
        : l10n.filterDateAny;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: () => _pick(context),
      onLongPress: hasRange ? () => onChanged(null) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          border: Border.all(color: colors.outline),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(Icons.date_range,
                color: colors.onSurfaceVariant, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: hasRange
                      ? colors.onSurface
                      : colors.onSurfaceVariant,
                ),
              ),
            ),
            if (hasRange)
              GestureDetector(
                onTap: () => onChanged(null),
                child: Icon(Icons.close,
                    color: colors.onSurfaceVariant, size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final initial = range == null
        ? null
        : material.DateTimeRange(start: range!.start, end: range!.end);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initial,
    );
    if (picked != null) {
      onChanged(DateTimeRange(start: picked.start, end: picked.end));
    }
  }
}
