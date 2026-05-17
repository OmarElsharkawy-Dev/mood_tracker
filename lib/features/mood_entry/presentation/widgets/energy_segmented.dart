import 'package:flutter/material.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_chip.dart';
import '../../domain/enums/energy_level.dart';

class EnergySegmented extends StatelessWidget {
  const EnergySegmented({super.key, required this.value, required this.onChanged});

  final EnergyLevel value;
  final ValueChanged<EnergyLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.logEntryFieldEnergy, style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.xxs),
        Wrap(
          spacing: AppSpacing.xxs,
          children: [
            for (final level in EnergyLevel.values)
              AppChip(
                label: _labelFor(l10n, level),
                selected: level == value,
                onTap: () => onChanged(level),
              ),
          ],
        ),
      ],
    );
  }

  String _labelFor(AppLocalizations l10n, EnergyLevel level) => switch (level) {
        EnergyLevel.veryLow => l10n.energyVeryLow,
        EnergyLevel.low => l10n.energyLow,
        EnergyLevel.medium => l10n.energyMedium,
        EnergyLevel.high => l10n.energyHigh,
        EnergyLevel.veryHigh => l10n.energyVeryHigh,
      };
}
