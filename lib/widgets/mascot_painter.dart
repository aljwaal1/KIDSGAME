import 'dart:math';
import 'package:flutter/material.dart';

enum MascotMood { happy, excited }

/// A hand-drawn, fully vector cartoon star character used as the app's
/// mascot on the home screen and in win celebrations. Matches the look of
/// the app launcher icon.
class StarMascot extends StatelessWidget {
  const StarMascot({super.key, this.size = 120, this.mood = MascotMood.happy});

  final double size;
  final MascotMood mood;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _StarMascotPainter(mood: mood)),
    );
  }
}

class _StarMascotPainter extends CustomPainter {
  _StarMascotPainter({required this.mood});

  final MascotMood mood;

  Path _starPath(Offset center, double outerR, double innerR, {int points = 5}) {
    final path = Path();
    final angleStep = 2 * pi / points;
    for (var i = 0; i < points; i++) {
      final outerAngle = -pi / 2 + i * angleStep;
      final outerPoint = center + Offset(cos(outerAngle), sin(outerAngle)) * outerR;
      if (i == 0) {
        path.moveTo(outerPoint.dx, outerPoint.dy);
      } else {
        path.lineTo(outerPoint.dx, outerPoint.dy);
      }
      final innerAngle = outerAngle + angleStep / 2;
      final innerPoint = center + Offset(cos(innerAngle), sin(innerAngle)) * innerR;
      path.lineTo(innerPoint.dx, innerPoint.dy);
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width * 0.46;
    final innerR = outerR * 0.58;

    // Soft shadow beneath the star.
    final shadowPath = _starPath(
      center.translate(0, size.height * 0.025),
      outerR,
      innerR,
    );
    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = const Color(0x33231046)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // White sticker-style outline.
    final outlinePath = _starPath(center, outerR * 1.05, innerR * 1.05);
    canvas.drawPath(outlinePath, Paint()..color = Colors.white);

    // Warm gradient body.
    final bodyPath = _starPath(center, outerR, innerR);
    final rect = Rect.fromCircle(center: center, radius: outerR);
    final bodyPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFD65C), Color(0xFFFFA726)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect);
    canvas.drawPath(bodyPath, bodyPaint);

    // Face.
    final eyeR = size.width * 0.052;
    final eyeY = center.dy - size.height * 0.02;
    final eyeDx = size.width * 0.105;
    final facePaint = Paint()..color = const Color(0xFF321E0A);
    final highlightPaint = Paint()..color = Colors.white.withOpacity(0.9);

    for (final sign in [-1.0, 1.0]) {
      final ex = center.dx + sign * eyeDx;
      if (mood == MascotMood.excited) {
        final happyEye = Path()
          ..moveTo(ex - eyeR, eyeY + eyeR * 0.2)
          ..quadraticBezierTo(ex, eyeY - eyeR * 1.1, ex + eyeR, eyeY + eyeR * 0.2);
        canvas.drawPath(
          happyEye,
          Paint()
            ..color = const Color(0xFF321E0A)
            ..style = PaintingStyle.stroke
            ..strokeWidth = size.width * 0.022
            ..strokeCap = StrokeCap.round,
        );
      } else {
        canvas.drawCircle(Offset(ex, eyeY), eyeR, facePaint);
        canvas.drawCircle(
          Offset(ex - eyeR * 0.32, eyeY - eyeR * 0.32),
          eyeR * 0.32,
          highlightPaint,
        );
      }
    }

    // Blush.
    final blushPaint = Paint()..color = const Color(0xFFFF9A91).withOpacity(0.75);
    final blushR = size.width * 0.045;
    final blushY = center.dy + size.height * 0.045;
    for (final sign in [-1.0, 1.0]) {
      canvas.drawCircle(
        Offset(center.dx + sign * size.width * 0.175, blushY),
        blushR,
        blushPaint,
      );
    }

    // Smile.
    final smileRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + size.height * 0.045),
      width: size.width * 0.16,
      height: size.height * 0.11,
    );
    canvas.drawArc(
      smileRect,
      mood == MascotMood.excited ? 0.2 : 0.35,
      mood == MascotMood.excited ? 2.74 : 2.44,
      false,
      Paint()
        ..color = const Color(0xFF321E0A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = size.width * 0.018
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _StarMascotPainter oldDelegate) {
    return oldDelegate.mood != mood;
  }
}
