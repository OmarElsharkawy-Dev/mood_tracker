import 'package:flutter/material.dart';

import '../../features/mood_entry/domain/enums/mood.dart';
import '../theme/app_colors.dart';

class MoodDot extends StatelessWidget {
  const MoodDot({super.key, required this.mood, this.size = 10});

  final Mood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: context.appColors.moodColor(mood),
      ),
    );
  }
}
