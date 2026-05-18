import 'package:flutter/foundation.dart';

@immutable
class ReminderSchedule {
  const ReminderSchedule({required this.enabled, required this.time});

  final bool enabled;
  final ({int hour, int minute}) time;

  static const ReminderSchedule disabledDefault = ReminderSchedule(
    enabled: false,
    time: (hour: 21, minute: 0),
  );

  String get prefsString {
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  static ({int hour, int minute})? parseTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parts = raw.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23) return null;
    if (m < 0 || m > 59) return null;
    return (hour: h, minute: m);
  }

  ReminderSchedule copyWith({bool? enabled, ({int hour, int minute})? time}) {
    return ReminderSchedule(
      enabled: enabled ?? this.enabled,
      time: time ?? this.time,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderSchedule &&
          enabled == other.enabled &&
          time.hour == other.time.hour &&
          time.minute == other.time.minute;

  @override
  int get hashCode => Object.hash(enabled, time.hour, time.minute);
}
