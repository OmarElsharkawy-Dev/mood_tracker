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

  test('forMood resolves all five enum cases', () {
    final c = AppColors.light;
    expect(c.forMood(Mood.awful), c.moodAwful);
    expect(c.forMood(Mood.bad), c.moodBad);
    expect(c.forMood(Mood.okay), c.moodOkay);
    expect(c.forMood(Mood.good), c.moodGood);
    expect(c.forMood(Mood.great), c.moodGreat);
  });
}
