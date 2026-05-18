import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/reminders/domain/reminder_schedule.dart';

void main() {
  group('ReminderSchedule', () {
    test('disabledDefault is enabled=false, time=21:00', () {
      const s = ReminderSchedule.disabledDefault;
      expect(s.enabled, false);
      expect(s.time.hour, 21);
      expect(s.time.minute, 0);
    });

    test('prefsString zero-pads hour and minute', () {
      const s = ReminderSchedule(enabled: true, time: (hour: 9, minute: 5));
      expect(s.prefsString, '09:05');
    });

    test('prefsString edge cases (23:59 and 00:00)', () {
      const a = ReminderSchedule(enabled: true, time: (hour: 23, minute: 59));
      const b = ReminderSchedule(enabled: true, time: (hour: 0, minute: 0));
      expect(a.prefsString, '23:59');
      expect(b.prefsString, '00:00');
    });

    test('parseTime accepts valid HH:mm strings', () {
      expect(ReminderSchedule.parseTime('21:00'), (hour: 21, minute: 0));
      expect(ReminderSchedule.parseTime('00:00'), (hour: 0, minute: 0));
      expect(ReminderSchedule.parseTime('09:05'), (hour: 9, minute: 5));
    });

    test('parseTime rejects malformed input', () {
      expect(ReminderSchedule.parseTime(null), isNull);
      expect(ReminderSchedule.parseTime(''), isNull);
      expect(ReminderSchedule.parseTime('oops'), isNull);
      expect(ReminderSchedule.parseTime('25:00'), isNull);
      expect(ReminderSchedule.parseTime('21:60'), isNull);
      expect(ReminderSchedule.parseTime('21'), isNull);
      expect(ReminderSchedule.parseTime('21:'), isNull);
    });
  });
}
