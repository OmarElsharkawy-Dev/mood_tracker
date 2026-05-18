import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mood_tracker/l10n/app_localizations.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/error/failure.dart';
import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/l10n/native_name.dart';
import '../../../../core/navigation/app_routes.dart';
import '../../../../core/widgets/error_view.dart';
import '../../providers/settings_controller.dart';
import '../widgets/language_picker_sheet.dart';
import '../widgets/settings_section.dart';
import '../widgets/settings_tile.dart';
import '../widgets/theme_picker_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final async = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: async.when(
        loading: () => Skeletonizer(
          child: ListView(
            children: [
              for (var i = 0; i < 4; i++)
                SettingsSection(
                  title: 'Section',
                  children: [
                    const SettingsTile(
                      leading: Icon(Icons.circle_outlined),
                      title: 'Loading setting',
                      subtitle: 'Loading value',
                      trailing: Icon(Icons.chevron_right),
                    ),
                  ],
                ),
            ],
          ),
        ),
        error: (e, _) => ErrorView(
          failure: e is Failure ? e : UnknownFailure(cause: e),
        ),
        data: (vm) => ListView(
          children: [
            SettingsSection(
              title: l10n.settingsAppearanceSection,
              children: [
                SettingsTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: l10n.settingsThemeLabel,
                  subtitle: _themeLabel(l10n, vm.themeMode),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => ThemePickerSheet.show(context),
                ),
              ],
            ),
            SettingsSection(
              title: l10n.settingsLanguageSection,
              children: [
                SettingsTile(
                  leading: const Icon(Icons.translate),
                  title: l10n.settingsLanguageLabel,
                  subtitle: nativeNameFor(vm.locale ?? const Locale('en')),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => LanguagePickerSheet.show(context),
                ),
              ],
            ),
            SettingsSection(
              title: l10n.settingsRemindersSection,
              children: [
                SettingsTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: l10n.settingsRemindersLabel,
                  subtitle: l10n.settingsRemindersComingSoon,
                  enabled: false,
                ),
              ],
            ),
            SettingsSection(
              title: l10n.settingsAboutSection,
              children: [
                SettingsTile(
                  leading: const Icon(Icons.info_outline),
                  title: l10n.settingsAboutLabel,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(AppRoutes.about),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _themeLabel(AppLocalizations l10n, ThemeMode mode) => switch (mode) {
        ThemeMode.light => l10n.themeLight,
        ThemeMode.dark => l10n.themeDark,
        ThemeMode.system => l10n.themeSystem,
      };
}
