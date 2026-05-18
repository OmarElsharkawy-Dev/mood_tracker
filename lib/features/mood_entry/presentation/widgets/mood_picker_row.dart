import 'package:flutter/material.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/mood_face.dart';
import '../../domain/enums/mood.dart';

class MoodPickerRow extends StatelessWidget {
  const MoodPickerRow({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final Mood? selected;
  final ValueChanged<Mood> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (final mood in Mood.values)
            _MoodPickerCell(
              mood: mood,
              label: _labelFor(l10n, mood),
              isSelected: mood == selected,
              onTap: () => onSelect(mood),
            ),
        ],
      ),
    );
  }

  String _labelFor(AppLocalizations l10n, Mood mood) => switch (mood) {
        Mood.awful => l10n.moodAwful,
        Mood.bad => l10n.moodBad,
        Mood.okay => l10n.moodOkay,
        Mood.good => l10n.moodGood,
        Mood.great => l10n.moodGreat,
      };
}

class _MoodPickerCell extends StatelessWidget {
  const _MoodPickerCell({
    required this.mood,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final Mood mood;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  static const double _circleSize = 56;
  static const double _faceSize = 48;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final moodColor = colors.moodColor(mood);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: _circleSize),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                width: _circleSize,
                height: _circleSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? moodColor.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: isSelected
                      ? Border.all(color: moodColor, width: 2)
                      : null,
                ),
                child: MoodFace(
                  mood: mood,
                  size: _faceSize,
                  color: moodColor,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                style: AppTextStyles.label.copyWith(
                  color: isSelected ? moodColor : colors.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
