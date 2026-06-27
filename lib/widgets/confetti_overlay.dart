import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, required this.child});
  final Widget child;
  @override
  State<ConfettiOverlay> createState() => ConfettiOverlayState();
}

class _ConfettiPiece {
  _ConfettiPiece(this.color, this.startX, this.delay, this.drift, this.rotation, this.size, this.circle);
  final Color color;
  final double startX;
  final double delay;
  final double drift;
  final double rotation;
  final double size;
  final bool circle;
}

class ConfettiOverlayState extends State<ConfettiOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
  final Random _random = Random();
  List<_ConfettiPiece> _pieces = <_ConfettiPiece>[];
  bool _active = false;

  static const List<Color> _colors = <Color>[
    Color(0xFFFFC857), Color(0xFFFF6B6B), Color(0xFF9EF01A),
    Color(0xFF06B6D4), Color(0xFF7C3AED), Color(0xFFFF8FAB),
  ];

  void burst({int count = 26}) {
    _pieces = List<_ConfettiPiece>.generate(count, (_) => _ConfettiPiece(
      _colors[_random.nextInt(_colors.length)],
      _random.nextDouble(),
      _random.nextDouble() * 0.25,
      (_random.nextDouble() - 0.5) * 2,
      (_random.nextDouble() - 0.5) * 8,
      6 + _random.nextDouble() * 8,
      _random.nextBool(),
    ));
    setState(() => _active = true);
    _controller
      ..stop()
      ..reset()
      ..forward().whenComplete(() { if (mounted) setState(() => _active = false); });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      widget.child,
      if (_active)
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(painter: _ConfettiPainter(_pieces, _controller.value)),
            ),
          ),
        ),
    ]);
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.progress);
  final List<_ConfettiPiece> pieces;
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final span = (1 - p.delay).clamp(0.0001, 1.0);
      var t = (progress - p.delay) / span;
      if (t <= 0) continue;
      if (t > 1) t = 1;
      final dx = p.startX * size.width + p.drift * 40 * t;
      final dy = size.height * 0.05 + t * size.height * 0.9;
      final paint = Paint()..color = p.color.withAlpha(((1 - t) * 255).round().clamp(0, 255));
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(p.rotation * t * pi);
      if (p.circle) {
        canvas.drawCircle(Offset.zero, p.size * 0.4, paint);
      } else {
        canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5), paint);
      }
      canvas.restore();
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
