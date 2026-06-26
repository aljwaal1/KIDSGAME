import 'package:flutter/material.dart';

enum MascotMood { happy, thinking }

class StarMascot extends StatelessWidget {
  const StarMascot({super.key, this.size = 90, this.mood = MascotMood.happy});

  final double size;
  final MascotMood mood;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _StarMascotPainter(mood)),
    );
  }
}

class _StarMascotPainter extends CustomPainter {
  _StarMascotPainter(this.mood);
  final MascotMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.42;
    final fill = Paint()..color = const Color(0xFFFFD65C);
    final edge = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final path = Path();
    for (int i = 0; i < 10; i++) {
      final angle = -1.5708 + i * 3.14159 / 5;
      final radius = i.isEven ? r : r * 0.48;
      final p = Offset(c.dx + radius * MathCos(angle), c.dy + radius * MathSin(angle));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, edge);

    final eye = Paint()..color = const Color(0xFF1E293B);
    canvas.drawCircle(Offset(c.dx - r * 0.24, c.dy - r * 0.08), r * 0.07, eye);
    canvas.drawCircle(Offset(c.dx + r * 0.24, c.dy - r * 0.08), r * 0.07, eye);

    final smile = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final mouth = Path();
    final top = mood == MascotMood.happy ? c.dy + r * 0.10 : c.dy + r * 0.20;
    mouth.moveTo(c.dx - r * 0.23, top);
    mouth.quadraticBezierTo(c.dx, c.dy + r * 0.34, c.dx + r * 0.23, top);
    canvas.drawPath(mouth, smile);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

double MathCos(double x) => _cos(x);
double MathSin(double x) => _sin(x);

// Small wrappers avoid importing dart:math in older generated snippets.
double _cos(double x) {
  // Taylor fallback is enough for the star icon; however dart:math is more accurate.
  return _Math.cos(x);
}

double _sin(double x) => _Math.sin(x);

class _Math {
  static double cos(double x) {
    // Use the VM math implementation through dart:math would be cleaner,
    // but keeping this file import-light avoids name conflicts in old projects.
    // Approximation is acceptable for a tiny decorative mascot.
    var term = 1.0;
    var sum = 1.0;
    for (var n = 1; n <= 6; n++) {
      term *= -x * x / ((2 * n - 1) * (2 * n));
      sum += term;
    }
    return sum;
  }

  static double sin(double x) {
    var term = x;
    var sum = x;
    for (var n = 1; n <= 6; n++) {
      term *= -x * x / ((2 * n) * (2 * n + 1));
      sum += term;
    }
    return sum;
  }
}
