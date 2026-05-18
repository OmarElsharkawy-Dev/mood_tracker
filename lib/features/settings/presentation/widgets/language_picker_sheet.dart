import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

import '../../../../core/l10n/locale_notifier.dart';
import '../../../../core/l10n/native_name.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class LanguagePickerSheet extends ConsumerWidget {
  const LanguagePickerSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.appColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheetBR),
      builder: (_) => const LanguagePickerSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(localeProvider) ?? const Locale('en');
    final locales = AppLocalizations.supportedLocales;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: RadioGroup<Locale>(
          groupValue: current,
          onChanged: (locale) =>
              locale == null ? null : _select(context, ref, locale),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final locale in locales)
                _Option(value: locale, label: nativeNameFor(locale)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _select(
      BuildContext context, WidgetRef ref, Locale locale) async {
    await ref.read(localeProvider.notifier).setLocale(locale);
    if (context.mounted) Navigator.of(context).pop();
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.value, required this.label});

  final Locale value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      onTap: () {
        RadioGroup.maybeOf<Locale>(context)?.onChanged(value);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          children: [
            Radio<Locale>(
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
