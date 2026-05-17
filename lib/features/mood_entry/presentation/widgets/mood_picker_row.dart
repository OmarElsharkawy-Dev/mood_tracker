import 'package:flutter/material.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mood_card.dart';
import '../../domain/enums/mood.dart';

class MoodPickerRow extends StatelessWidget {
  const MoodPickerRow({super.key, required this.selected, required this.onSelect});

  final Mood? selected;
  final ValueChanged<Mood> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final mood in Mood.values)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxs / 2),
            child: MoodCard(
              mood: mood,
              label: _labelFor(l10n, mood),
              isSelected: selected == mood,
              onTap: () => onSelect(mood),
            ),
          ),
      ],
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
