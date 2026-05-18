import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

import '../../../../core/l10n/context_l10n_extension.dart';
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
    final async = ref.watch(reminderControllerProvider);
    final permission = ref.watch(permissionStatusProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.remindersTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        // ignore: avoid_types_on_closure_parameters
        error: (e, _) => Center(child: Text(l10n.errorRetry)),
        data: (schedule) => ListView(
          children: [
            SettingsTile(
              leading: const Icon(Icons.notifications_outlined),
              title: l10n.remindersEnabledTitle,
              trailing: Switch(
                value: schedule.enabled,
                onChanged: (v) => ref
                    .read(reminderControllerProvider.notifier)
                    .setEnabled(
                      v,
                      title: l10n.reminderNotificationTitle,
                      body: l10n.reminderNotificationBody,
                    ),
              ),
            ),
            SettingsTile(
              leading: const Icon(Icons.schedule),
              title: l10n.remindersTimeTitle,
              subtitle: _formatTime(schedule.time.hour, schedule.time.minute),
              trailing: const Icon(Icons.chevron_right),
              enabled: schedule.enabled,
              onTap: () async {
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
              },
            ),
            permission.maybeWhen(
              data: (p) {
                if (p == NotificationPermissionStatus.granted) {
                  return const SizedBox.shrink();
                }
                return PermissionDeniedCard(
                  onOpenSettings: ph.openAppSettings,
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
