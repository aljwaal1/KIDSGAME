import 'package:flutter/material.dart';

class WinLinePainter extends CustomPainter {
  const WinLinePainter(this.line, {this.progress = 1.0});

  final List<int> line;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (line.length != 3) return;
    final cell = size.width / 3;
    Offset centerOf(int index) {
      final row = index ~/ 3;
      final col = index % 3;
      return Offset(col * cell + cell / 2, row * cell + cell / 2);
    }

    final start = centerOf(line.first);
    final fullEnd = centerOf(line.last);
    final end = Offset.lerp(start, fullEnd, progress) ?? fullEnd;
    final paint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant WinLinePainter oldDelegate) {
    return oldDelegate.line.join(',') != line.join(',') ||
        oldDelegate.progress != progress;
  }
}
