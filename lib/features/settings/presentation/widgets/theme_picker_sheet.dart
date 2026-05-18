import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_notifier.dart';

class ThemePickerSheet extends ConsumerWidget {
  const ThemePickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBR),
      builder: (_) => const ThemePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final current = ref.watch(themeModeProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: RadioGroup<ThemeMode>(
          groupValue: current,
          onChanged: (mode) =>
              mode == null ? null : _select(context, ref, mode),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Option(value: ThemeMode.light, label: l10n.themeLight),
              _Option(value: ThemeMode.dark, label: l10n.themeDark),
              _Option(value: ThemeMode.system, label: l10n.themeSystem),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _select(
      BuildContext context, WidgetRef ref, ThemeMode mode) async {
    await ref.read(themeModeProvider.notifier).setMode(mode);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.value, required this.label});

  final ThemeMode value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: () {
        RadioGroup.maybeOf<ThemeMode>(context)?.onChanged(value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Radio<ThemeMode>(
              value: value,
              activeColor: colors.primary,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                label,
                style:
                    AppTextStyles.body.copyWith(color: colors.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
