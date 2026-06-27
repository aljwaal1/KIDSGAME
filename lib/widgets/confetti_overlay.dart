import 'dart:math';
import 'package:flutter/material.dart';

class ConfettiOverlay extends StatefulWidget {
  const ConfettiOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<ConfettiOverlay> createState() => ConfettiOverlayState();
}

class _ConfettiPiece {
  _ConfettiPiece({
    required this.color,
    required this.startX,
    required this.delay,
    required this.horizontalDrift,
    required this.rotationSpeed,
    required this.size,
    required this.isCircle,
  });

  final Color color;
  final double startX;
  final double delay;
  final double horizontalDrift;
  final double rotationSpeed;
  final double size;
  final bool isCircle;
}

class ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  );
  final Random _random = Random();
  List<_ConfettiPiece> _pieces = const [];
  bool _active = false;

  static const List<Color> _palette = [
    Color(0xFFFFC857),
    Color(0xFFFF6B6B),
    Color(0xFF9EF01A),
    Color(0xFF06B6D4),
    Color(0xFF7C3AED),
    Color(0xFFFF8FAB),
  ];

  void burst({int count = 26}) {
    _pieces = List.generate(count, (_) {
      return _ConfettiPiece(
        color: _palette[_random.nextInt(_palette.length)],
        startX: _random.nextDouble(),
        delay: _random.nextDouble() * 0.25,
        horizontalDrift: (_random.nextDouble() - 0.5) * 2,
        rotationSpeed: (_random.nextDouble() - 0.5) * 8,
        size: 6 + _random.nextDouble() * 7,
        isCircle: _random.nextBool(),
      );
    });
    setState(() => _active = true);
    _controller
      ..stop()
      ..reset()
      ..forward().whenComplete(() {
        if (mounted) setState(() => _active = false);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_active)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ConfettiPainter(
                      pieces: _pieces,
                      progress: _controller.value,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.pieces, required this.progress});

  final List<_ConfettiPiece> pieces;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    for (final piece in pieces) {
      final span = (1 - piece.delay).clamp(0.0001, 1.0);
      var t = (progress - piece.delay) / span;
      if (t <= 0) continue;
      if (t > 1) t = 1;
      final fallY = t * (size.height * 0.9);
      final dx = piece.startX * size.width + piece.horizontalDrift * 40 * t;
      final dy = size.height * 0.05 + fallY;
      final opacity = (1 - t).clamp(0.0, 1.0).toDouble();
      final paint = Paint()..color = piece.color.withOpacity(opacity);
      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(piece.rotationSpeed * t * pi);
      if (piece.isCircle) {
        canvas.drawCircle(Offset.zero, piece.size * 0.4, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: piece.size,
            height: piece.size * 0.5,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
