import 'package:flutter/material.dart';

import '../../../../core/widgets/mood_face.dart';
import '../../../mood_entry/domain/enums/mood.dart';

class IllustrationHow extends StatelessWidget {
  const IllustrationHow({
    super.key,
    required this.color,
    required this.accent,
    this.size = 200,
  });

  final Color color;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _CardAndFingerPainter(card: accent, finger: color),
          ),
          Align(
            alignment: const Alignment(0, -0.15),
            child: MoodFace(mood: Mood.great, color: accent, size: size * 0.28),
          ),
        ],
      ),
    );
  }
}

class _CardAndFingerPainter extends CustomPainter {
  _CardAndFingerPainter({required this.card, required this.finger});

  final Color card;
  final Color finger;

  @override
  void paint(Canvas canvas, Size size) {
    final cardStroke = Paint()
      ..color = card
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final cardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.18, size.height * 0.18,
          size.width * 0.64, size.height * 0.58),
      const Radius.circular(20),
    );
    canvas.drawRRect(cardRect, cardStroke);

    final fingerPaint = Paint()
      ..color = finger
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Finger: rounded rectangle (the finger) + small circle (the fingertip dot)
    final fingerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.55, size.height * 0.58,
          size.width * 0.12, size.height * 0.26),
      const Radius.circular(20),
    );
    canvas.drawRRect(fingerRect, fingerPaint);

    canvas.drawCircle(
      Offset(size.width * 0.61, size.height * 0.55),
      size.width * 0.025,
      fingerPaint..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _CardAndFingerPainter old) =>
      old.card != card || old.finger != finger;
}
