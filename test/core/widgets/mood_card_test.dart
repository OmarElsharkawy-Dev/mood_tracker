import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/core/widgets/mood_card.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';

void main() {
  testWidgets('MoodCard fires onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: Scaffold(
        body: MoodCard(
          mood: Mood.good,
          label: 'Good',
          isSelected: false,
          onTap: () => taps++,
        ),
      ),
    ));
    await tester.tap(find.byType(MoodCard));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('MoodCard renders label', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: Scaffold(
        body: MoodCard(
          mood: Mood.good,
          label: 'Good',
          isSelected: true,
          onTap: () {},
        ),
      ),
    ));
    expect(find.text('Good'), findsOneWidget);
  });
}
