import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/theme/app_colors.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';

void main() {
  testWidgets('context.appColors returns the registered AppColors', (tester) async {
    late AppColors readBack;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(extensions: const [AppColors.light]),
      home: Builder(builder: (ctx) {
        readBack = ctx.appColors;
        return const SizedBox.shrink();
      }),
    ));
    expect(readBack.primary, AppColors.light.primary);
  });

  test('moodColor resolves all five enum cases', () {
    final c = AppColors.light;
    expect(c.moodColor(Mood.awful), c.moodAwful);
    expect(c.moodColor(Mood.bad), c.moodBad);
    expect(c.moodColor(Mood.okay), c.moodOkay);
    expect(c.moodColor(Mood.good), c.moodGood);
    expect(c.moodColor(Mood.great), c.moodGreat);
  });
}
