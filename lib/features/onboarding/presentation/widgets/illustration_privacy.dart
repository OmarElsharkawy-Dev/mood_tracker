import 'package:flutter/material.dart';

import '../../../../core/widgets/mood_face.dart';
import '../../../mood_entry/domain/enums/mood.dart';

class IllustrationPrivacy extends StatelessWidget {
  const IllustrationPrivacy({super.key, required this.color, this.size = 200});

  final Color color;
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
            painter: _PhoneAndLockPainter(color: color),
          ),
          Align(
            alignment: const Alignment(-0.32, 0.3),
            child: MoodFace(mood: Mood.bad, color: color, size: size * 0.14),
          ),
          Align(
            alignment: Alignment.center.add(const Alignment(0, 0.3)),
            child: MoodFace(mood: Mood.okay, color: color, size: size * 0.14),
          ),
          Align(
            alignment: const Alignment(0.32, 0.3),
            child: MoodFace(mood: Mood.good, color: color, size: size * 0.14),
          ),
        ],
      ),
    );
  }
}

class _PhoneAndLockPainter extends CustomPainter {
  _PhoneAndLockPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Phone outline
    final phoneRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.28, size.height * 0.18,
          size.width * 0.44, size.height * 0.74),
      const Radius.circular(20),
    );
    canvas.drawRRect(phoneRect, stroke);

    // Padlock above the phone
    final lockBodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.42, size.height * 0.06,
          size.width * 0.16, size.height * 0.1),
      const Radius.circular(4),
    );
    canvas.drawRRect(lockBodyRect, stroke);

    // Padlock shackle
    final shacklePath = Path()
      ..moveTo(size.width * 0.44, size.height * 0.06)
      ..arcToPoint(
        Offset(size.width * 0.56, size.height * 0.06),
        radius: const Radius.circular(8),
        clockwise: true,
      )
      ..lineTo(size.width * 0.56, size.height * 0.06);
    canvas.drawPath(shacklePath, stroke);
  }

  @override
  bool shouldRepaint(covariant _PhoneAndLockPainter old) => old.color != color;
}
