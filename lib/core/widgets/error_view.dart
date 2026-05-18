import 'package:flutter/material.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';

import '../error/failure.dart';
import '../l10n/context_l10n_extension.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.failure, this.onRetry});

  final Failure failure;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: colors.error, size: 36),
          const SizedBox(height: AppSpacing.xs),
          Text(l10n.errorTitle,
              style: AppTextStyles.title.copyWith(color: colors.onSurface)),
          const SizedBox(height: AppSpacing.xs),
          Text(_describe(l10n, failure),
              style: AppTextStyles.body.copyWith(color: colors.onSurfaceVariant),
              textAlign: TextAlign.center),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            FilledButton(onPressed: onRetry, child: Text(l10n.errorRetry)),
          ],
        ],
      ),
    );
  }

  String _describe(AppLocalizations l10n, Failure f) => switch (f) {
        DatabaseFailure() => l10n.errorDatabase,
        NotFoundFailure() => l10n.errorNotFound,
        ValidationFailure(:final fieldErrors) =>
          fieldErrors.containsKey('intensity')
              ? l10n.errorValidationIntensity
              : (fieldErrors.containsKey('sleepHours')
                  ? l10n.errorValidationSleepHours
                  : l10n.errorUnknown),
        IOFailure() => l10n.errorUnknown,
        UnknownFailure() => l10n.errorUnknown,
      };
}
