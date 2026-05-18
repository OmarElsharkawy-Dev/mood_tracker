import 'package:flutter/material.dart';

class ReminderTimePickerSheet {
  static Future<({int hour, int minute})?> show(
    BuildContext context, {
    required int initialHour,
    required int initialMinute,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
    );
    if (picked == null) return null;
    return (hour: picked.hour, minute: picked.minute);
  }
}
