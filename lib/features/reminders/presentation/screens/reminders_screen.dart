import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:skeletonizer/skeletonizer.dart';

import '../../../../core/l10n/context_l10n_extension.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../settings/presentation/widgets/settings_tile.dart';
import '../../data/notification_service.dart';
import '../../providers/permission_status_provider.dart';
import '../../providers/reminder_controller.dart';
import '../widgets/permission_denied_card.dart';
import '../widgets/reminder_time_picker_sheet.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final colors = context.appColors;
    final async = ref.watch(reminderControllerProvider);
    final permission = ref.watch(permissionStatusProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.remindersTitle,
          style:
              AppTextStyles.headline.copyWith(color: colors.onBackground),
        ),
      ),
      body: async.when(
        loading: () => Skeletonizer(
          child: ListView(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            children: [
              SettingsTile(
                leading: const Icon(Icons.notifications_outlined),
                title: l10n.remindersEnabledTitle,
                trailing: const Switch(value: false, onChanged: null),
              ),
              const SizedBox(height: AppSpacing.md),
              _TimeCard(
                  label: l10n.remindersTimeTitle,
                  time: '21:00',
                  enabled: false),
            ],
          ),
        ),
        error: (e, _) => Center(child: Text(l10n.errorRetry)),
        data: (schedule) => ListView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          children: [
            SettingsTile(
              leading: const Icon(Icons.notifications_outlined),
              title: l10n.remindersEnabledTitle,
              trailing: Switch(
                value: schedule.enabled,
                thumbColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? colors.primary
                        : null),
                trackColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? colors.primary.withValues(alpha: 0.3)
                        : null),
                onChanged: (v) => ref
                    .read(reminderControllerProvider.notifier)
                    .setEnabled(
                      v,
                      title: l10n.reminderNotificationTitle,
                      body: l10n.reminderNotificationBody,
                    ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            _TimeCard(
              label: l10n.remindersTimeTitle,
              time: _formatTime(schedule.time.hour, schedule.time.minute),
              enabled: schedule.enabled,
              onTap: schedule.enabled
                  ? () async {
                      final picked = await ReminderTimePickerSheet.show(
                        context,
                        initialHour: schedule.time.hour,
                        initialMinute: schedule.time.minute,
                      );
                      if (picked != null && context.mounted) {
                        await ref
                            .read(reminderControllerProvider.notifier)
                            .setTime(
                              hour: picked.hour,
                              minute: picked.minute,
                              title: l10n.reminderNotificationTitle,
                              body: l10n.reminderNotificationBody,
                            );
                      }
                    }
                  : null,
            ),
            permission.maybeWhen(
              data: (p) {
                if (p == NotificationPermissionStatus.granted) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: PermissionDeniedCard(
                    onOpenSettings: ph.openAppSettings,
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final hh = hour.toString().padLeft(2, '0');
    final mm = minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.label,
    required this.time,
    required this.enabled,
    this.onTap,
  });

  final String label;
  final String time;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.label.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  time,
                  style: AppTextStyles.display.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
