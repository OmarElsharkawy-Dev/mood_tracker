import 'package:flutter/material.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/enums/energy_level.dart';

class EnergySegmented extends StatelessWidget {
  const EnergySegmented({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final EnergyLevel value;
  final ValueChanged<EnergyLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.logEntryFieldEnergy,
          style: AppTextStyles.label.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final level in EnergyLevel.values)
              _EnergyChip(
                label: _labelFor(l10n, level),
                isSelected: level == value,
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

class _EnergyChip extends StatelessWidget {
  const _EnergyChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bg = isSelected ? colors.primary : colors.surfaceVariant;
    final fg = isSelected ? colors.onPrimary : colors.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm,
          horizontal: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: AppTextStyles.label.copyWith(color: fg),
        ),
      ),
    );
  }
}
