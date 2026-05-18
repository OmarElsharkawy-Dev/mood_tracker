import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mood_tracker/features/onboarding/presentation/widgets/illustration_how.dart';
import 'package:mood_tracker/features/onboarding/presentation/widgets/illustration_privacy.dart';
import 'package:mood_tracker/features/onboarding/presentation/widgets/illustration_what.dart';

void main() {
  testWidgets('illustrations pump without exceptions', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            IllustrationWhat(color: Colors.black),
            IllustrationHow(color: Colors.black, accent: Colors.purple),
            IllustrationPrivacy(color: Colors.black),
          ],
        ),
      ),
    ));
    expect(find.byType(IllustrationWhat), findsOneWidget);
    expect(find.byType(IllustrationHow), findsOneWidget);
    expect(find.byType(IllustrationPrivacy), findsOneWidget);
  });
}
