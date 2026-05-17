import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../features/mood_entry/domain/enums/mood.dart';

/// Programmatic mood face. Curvature interpolates between awful (deep frown)
/// and great (wide smile). [strength] in [0..1] modulates feature size for
/// intensity overlays — phase 1 always renders at 1.0.
class MoodFace extends StatelessWidget {
  const MoodFace({
    super.key,
    required this.mood,
    this.color,
    this.size = 56,
    this.strokeWidth = 2.4,
    this.strength = 1.0,
  });

  final Mood mood;
  final Color? color;
  final double size;
  final double strokeWidth;
  final double strength;

  @override
  Widget build(BuildContext context) {
    final paintColor = color ?? Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _MoodFacePainter(
          mood: mood,
          color: paintColor,
          strokeWidth: strokeWidth,
          strength: strength,
        ),
      ),
    );
  }
}

class _MoodFacePainter extends CustomPainter {
  _MoodFacePainter({
    required this.mood,
    required this.color,
    required this.strokeWidth,
    required this.strength,
  });

  final Mood mood;
  final Color color;
  final double strokeWidth;
  final double strength;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) / 2 - strokeWidth;

    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Outer circle
    canvas.drawCircle(center, r, stroke);

    // Eyes
    final eyeY = center.dy - r * 0.22;
    final eyeDx = r * 0.38;
    final eyeR = (r * 0.06) * strength.clamp(0.6, 1.2);
    final eyePaint = Paint()..color = color;
    canvas.drawCircle(Offset(center.dx - eyeDx, eyeY), eyeR, eyePaint);
    canvas.drawCircle(Offset(center.dx + eyeDx, eyeY), eyeR, eyePaint);

    // Mouth: curvature -1 (deep frown) → +1 (wide smile)
    final curvature = switch (mood) {
      Mood.awful => -1.0,
      Mood.bad => -0.5,
      Mood.okay => 0.0,
      Mood.good => 0.55,
      Mood.great => 1.0,
    };

    final mouthCenter = Offset(center.dx, center.dy + r * 0.28);
    final mouthHalfWidth = r * 0.42;
    final mouthSag = r * 0.32 * curvature * strength;

    if (curvature.abs() < 0.05) {
      // Straight line for okay
      canvas.drawLine(
        Offset(mouthCenter.dx - mouthHalfWidth, mouthCenter.dy),
        Offset(mouthCenter.dx + mouthHalfWidth, mouthCenter.dy),
        stroke,
      );
    } else {
      final path = Path()
        ..moveTo(mouthCenter.dx - mouthHalfWidth, mouthCenter.dy)
        ..quadraticBezierTo(
          mouthCenter.dx,
          mouthCenter.dy + mouthSag,
          mouthCenter.dx + mouthHalfWidth,
          mouthCenter.dy,
        );
      canvas.drawPath(path, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _MoodFacePainter old) =>
      old.mood != mood ||
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.strength != strength;
}
