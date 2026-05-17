import 'package:flutter/material.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/mood_card.dart';
import '../../../mood_entry/domain/enums/mood.dart';

class QuickLogRow extends StatelessWidget {
  const QuickLogRow({super.key, required this.onPick});

  final ValueChanged<Mood> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final mood in Mood.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: MoodCard(
                mood: mood,
                label: _label(l10n, mood),
                isSelected: false,
                onTap: () => onPick(mood),
              ),
            ),
        ],
      ),
    );
  }

  String _label(AppLocalizations l10n, Mood mood) => switch (mood) {
        Mood.awful => l10n.moodAwful,
        Mood.bad => l10n.moodBad,
        Mood.okay => l10n.moodOkay,
        Mood.good => l10n.moodGood,
        Mood.great => l10n.moodGreat,
      };
}
