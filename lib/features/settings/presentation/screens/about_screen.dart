import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/mood_face.dart';
import '../../../mood_entry/domain/enums/mood.dart';
import '../../providers/settings_controller.dart';
import '../widgets/settings_tile.dart';

class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final async = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.aboutTitle)),
      body: async.when(
        loading: () => Skeletonizer(
          child: ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(Icons.circle_outlined, size: 64),
                    SizedBox(height: 8),
                    Text('App Title'),
                    SizedBox(height: 4),
                    Text('Version 0.0.0'),
                    SizedBox(height: 16),
                    Text('Loading description text here'),
                  ],
                ),
              ),
              SettingsTile(
                leading: const Icon(Icons.description_outlined),
                title: 'Loading item',
                trailing: const Icon(Icons.chevron_right),
              ),
            ],
          ),
        ),
        error: (_, _) => const SizedBox.shrink(),
        data: (vm) => ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  MoodFace(mood: Mood.good, color: colors.primary, size: 64),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.appTitle, style: AppTextStyles.headline),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    '${l10n.aboutVersion} ${vm.appVersion}',
                    style:
                        AppTextStyles.bodySmall.copyWith(color: colors.onMuted),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    l10n.aboutDescription,
                    style: AppTextStyles.body.copyWith(color: colors.onMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SettingsTile(
              leading: const Icon(Icons.description_outlined),
              title: l10n.aboutViewLicenses,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLicensePage(
                context: context,
                applicationName: l10n.appTitle,
                applicationVersion: vm.appVersion,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
