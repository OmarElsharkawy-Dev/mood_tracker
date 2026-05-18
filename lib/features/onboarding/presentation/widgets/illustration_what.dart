import 'package:flutter/material.dart';

import '../../../../core/widgets/mood_face.dart';
import '../../../mood_entry/domain/enums/mood.dart';

class IllustrationWhat extends StatelessWidget {
  const IllustrationWhat({super.key, required this.color, this.size = 200});

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
            painter: _JournalPainter(color: color),
          ),
          MoodFace(mood: Mood.good, color: color, size: size * 0.32),
        ],
      ),
    );
  }
}

class _JournalPainter extends CustomPainter {
  _JournalPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final pageRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.18, size.height * 0.12,
          size.width * 0.64, size.height * 0.76),
      const Radius.circular(12),
    );
    canvas.drawRRect(pageRect, stroke);

    // Header line (just above the face)
    canvas.drawLine(
      Offset(size.width * 0.28, size.height * 0.26),
      Offset(size.width * 0.6, size.height * 0.26),
      stroke,
    );

    // Lines below the face
    for (var i = 0; i < 3; i++) {
      final y = size.height * (0.72 + i * 0.07);
      canvas.drawLine(
        Offset(size.width * 0.28, y),
        Offset(size.width * (0.72 - i * 0.06), y),
        stroke,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _JournalPainter old) => old.color != color;
}
