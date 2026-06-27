import 'package:flutter/material.dart';

class WinLinePainter extends CustomPainter {
  const WinLinePainter(this.line, {this.progress = 1.0});
  final List<int> line;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    if (line.length != 3) return;
    final cell = size.width / 3;
    Offset center(int index) => Offset((index % 3) * cell + cell / 2, (index ~/ 3) * cell + cell / 2);
    final start = center(line.first);
    final end = Offset.lerp(start, center(line.last), progress) ?? center(line.last);
    final paint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint);
  }
  @override
  bool shouldRepaint(covariant WinLinePainter oldDelegate) => oldDelegate.line.join(',') != line.join(',') || oldDelegate.progress != progress;
}
