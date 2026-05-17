import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/core/widgets/mood_face.dart';
import 'package:mood_tracker/features/mood_entry/domain/enums/mood.dart';

Future<void> _pumpFace(WidgetTester tester, Mood mood) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: MoodFace(mood: mood, color: Colors.black, size: 80),
      ),
    ),
  ));
}

void main() {
  for (final mood in Mood.values) {
    testWidgets('MoodFace renders ${mood.name} matching golden', (tester) async {
      await _pumpFace(tester, mood);
      await expectLater(
        find.byType(MoodFace),
        matchesGoldenFile('goldens/mood_face_${mood.name}.png'),
      );
    });
  }
}
