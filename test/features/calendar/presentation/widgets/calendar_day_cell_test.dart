import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/calendar/domain/day_mood_summary.dart';
import 'package:mood_tracker/features/calendar/presentation/widgets/calendar_day_cell.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('renders MoodDot when summary is set, no badge for single entry',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: Scaffold(
        body: CalendarDayCell(
          date: DateTime(2026, 5, 17),
          summary: DayMoodSummary(
            date: DateTime(2026, 5, 17),
            averageMood: Mood.good,
            entryCount: 1,
          ),
          isCurrentMonth: true,
          isToday: false,
        ),
      ),
    ));
    expect(find.text('17'), findsOneWidget);
    expect(find.text('×1'), findsNothing);
  });

  testWidgets('renders ×N badge when entryCount > 1', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: Scaffold(
        body: CalendarDayCell(
          date: DateTime(2026, 5, 17),
          summary: DayMoodSummary(
            date: DateTime(2026, 5, 17),
            averageMood: Mood.good,
            entryCount: 3,
          ),
          isCurrentMonth: true,
          isToday: false,
        ),
      ),
    ));
    expect(find.text('×3'), findsOneWidget);
  });

  testWidgets('is non-tappable when outside current month', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: Scaffold(
        body: CalendarDayCell(
          date: DateTime(2026, 4, 30),
          summary: DayMoodSummary(
            date: DateTime(2026, 4, 30),
            averageMood: Mood.good,
            entryCount: 1,
          ),
          isCurrentMonth: false,
          isToday: false,
          onTap: () => taps++,
        ),
      ),
    ));
    await tester.tap(find.byType(CalendarDayCell));
    await tester.pump();
    expect(taps, 0);
  });
}
