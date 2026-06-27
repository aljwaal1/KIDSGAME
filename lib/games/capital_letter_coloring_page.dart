import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class CapitalLetterColoringPage extends StatefulWidget {
  const CapitalLetterColoringPage({super.key});

  @override
  State<CapitalLetterColoringPage> createState() => _CapitalLetterColoringPageState();
}

class _CapitalLetterColoringPageState extends State<CapitalLetterColoringPage> {
  static const List<String> _letters = <String>[
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  static const List<Color> _palette = <Color>[
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFF22C55E),
    Color(0xFFF97316),
  ];

  final List<_PaintDot> _dots = <_PaintDot>[];
  int _letterIndex = 0;
  int _colorIndex = 0;
  bool _celebrated = false;

  String get _letter => _letters[_letterIndex];
  Color get _selectedColor => _palette[_colorIndex];
  double get _progress => (_dots.length / 100).clamp(0.0, 1.0).toDouble();

  void _addDot(Offset position) {
    setState(() {
      _dots.add(_PaintDot(position, _selectedColor));
      if (_dots.length > 180) _dots.removeAt(0);
    });
    if (_progress >= 0.92 && !_celebrated) {
      _celebrated = true;
      ScoreService.instance.addStars(2);
      SoundService.instance.play('win.wav');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('أحسنت! لوّنت حرف $_letter')),
        );
      }
    }
  }

  void _clear() {
    setState(() {
      _dots.clear();
      _celebrated = false;
    });
    SoundService.instance.play('click.wav');
  }

  void _nextLetter() {
    setState(() {
      _letterIndex = (_letterIndex + 1) % _letters.length;
      _dots.clear();
      _celebrated = false;
    });
    SoundService.instance.play('chime.wav');
  }

  void _previousLetter() {
    setState(() {
      _letterIndex = (_letterIndex - 1 + _letters.length) % _letters.length;
      _dots.clear();
      _celebrated = false;
    });
    SoundService.instance.play('click.wav');
  }

  void _sayLetter() {
    SoundService.instance.play('tap.wav');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('الحرف الحالي: $_letter')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('تلوين الحروف الكبيرة'),
        actions: <Widget>[
          IconButton(tooltip: 'إعادة التلوين', onPressed: _clear, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Column(
            children: <Widget>[
              _Header(letter: _letter, progress: _progress),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Listener(
                    onPointerDown: (PointerDownEvent event) {
                      SoundService.instance.play('move.wav');
                      final box = context.findRenderObject();
                      if (box is RenderBox) {
                        _addDot(box.globalToLocal(event.position));
                      }
                    },
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onPanStart: (DragStartDetails details) => _addDot(details.localPosition),
                          onPanUpdate: (DragUpdateDetails details) => _addDot(details.localPosition),
                          child: CustomPaint(
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                            painter: _LetterColoringPainter(
                              letter: _letter,
                              dots: List<_PaintDot>.from(_dots),
                              progress: _progress,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _ColorPicker(colors: _palette, selectedIndex: _colorIndex, onSelect: (int index) {
                setState(() => _colorIndex = index);
                SoundService.instance.play('click.wav');
              }),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(child: OutlinedButton.icon(onPressed: _previousLetter, icon: const Icon(Icons.arrow_back_rounded), label: const Text('السابق'))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton.icon(onPressed: _sayLetter, icon: const Icon(Icons.volume_up_rounded), label: Text(_letter))),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton.icon(onPressed: _nextLetter, icon: const Icon(Icons.arrow_forward_rounded), label: const Text('التالي'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaintDot {
  const _PaintDot(this.position, this.color);
  final Offset position;
  final Color color;
}

class _Header extends StatelessWidget {
  const _Header({required this.letter, required this.progress});
  final String letter;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final percent = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF4F46E5), Color(0xFFEC4899)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Text(letter, style: const TextStyle(color: Color(0xFF4F46E5), fontSize: 34, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('لوّن داخل الحرف واتبع السهم', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Changa')),
                const SizedBox(height: 5),
                Text('التقدم: $percent%', style: const TextStyle(color: Color(0xFFFFF7D6))),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0x55FFFFFF),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD65C)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.colors, required this.selectedIndex, required this.onSelect});
  final List<Color> colors;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: <Widget>[
            const Text('الألوان', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Changa')),
            const Spacer(),
            for (var i = 0; i < colors.length; i++)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onSelect(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: selectedIndex == i ? 42 : 36,
                    height: selectedIndex == i ? 42 : 36,
                    decoration: BoxDecoration(
                      color: colors[i],
                      shape: BoxShape.circle,
                      border: Border.all(color: selectedIndex == i ? const Color(0xFF111827) : Colors.white, width: selectedIndex == i ? 4 : 3),
                      boxShadow: <BoxShadow>[BoxShadow(color: colors[i].withAlpha(85), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LetterColoringPainter extends CustomPainter {
  const _LetterColoringPainter({required this.letter, required this.dots, required this.progress});
  final String letter;
  final List<_PaintDot> dots;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF8FAFC));
    _paintGuide(canvas, size);

    for (final dot in dots) {
      final paint = Paint()..color = dot.color.withAlpha(215);
      canvas.drawCircle(dot.position, size.shortestSide * 0.045, paint);
      canvas.drawCircle(dot.position, size.shortestSide * 0.020, Paint()..color = Colors.white.withAlpha(120));
    }

    _paintLetter(canvas, size, PaintingStyle.stroke, const Color(0xFF0F172A), 10);
    _paintLetter(canvas, size, PaintingStyle.stroke, const Color(0xFF94A3B8), 3);
    _paintArrow(canvas, size);
  }

  void _paintGuide(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E7FF)
      ..strokeWidth = 2;
    for (var x = 0.0; x <= size.width; x += size.width / 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += size.height / 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _paintArrow(Canvas canvas, Size size) {
    final path = _guidePath(size);
    final shadow = Paint()
      ..color = Colors.white.withAlpha(220)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final paint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, shadow);
    canvas.drawPath(path, paint);

    final metric = path.computeMetrics().isEmpty ? null : path.computeMetrics().first;
    if (metric == null) return;
    final tangent = metric.getTangentForOffset(metric.length * 0.72);
    if (tangent == null) return;
    _drawArrowHead(canvas, tangent.position, tangent.angle, const Color(0xFFF59E0B));

    final start = metric.getTangentForOffset(0)?.position ?? Offset(size.width * 0.25, size.height * 0.20);
    canvas.drawCircle(start, 12, Paint()..color = const Color(0xFF22C55E));
    final tp = TextPainter(text: const TextSpan(text: 'ابدأ', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)), textDirection: TextDirection.rtl)..layout();
    tp.paint(canvas, start.translate(-tp.width / 2, -tp.height / 2));
  }

  Path _guidePath(Size size) {
    final w = size.width;
    final h = size.height;
    switch (letter) {
      case 'A':
        return Path()
          ..moveTo(w * 0.30, h * 0.78)
          ..lineTo(w * 0.50, h * 0.18)
          ..lineTo(w * 0.70, h * 0.78)
          ..moveTo(w * 0.40, h * 0.55)
          ..lineTo(w * 0.60, h * 0.55);
      case 'B':
        return Path()
          ..moveTo(w * 0.35, h * 0.18)
          ..lineTo(w * 0.35, h * 0.80)
          ..moveTo(w * 0.35, h * 0.20)
          ..quadraticBezierTo(w * 0.75, h * 0.25, w * 0.42, h * 0.50)
          ..quadraticBezierTo(w * 0.78, h * 0.72, w * 0.35, h * 0.80);
      default:
        return Path()
          ..moveTo(w * 0.28, h * 0.24)
          ..quadraticBezierTo(w * 0.50, h * 0.08, w * 0.72, h * 0.24)
          ..quadraticBezierTo(w * 0.86, h * 0.50, w * 0.70, h * 0.75)
          ..quadraticBezierTo(w * 0.48, h * 0.92, w * 0.28, h * 0.75);
    }
  }

  void _drawArrowHead(Canvas canvas, Offset tip, double angle, Color color) {
    const length = 24.0;
    final p1 = Offset(tip.dx - length * math.cos(angle - math.pi / 6), tip.dy - length * math.sin(angle - math.pi / 6));
    final p2 = Offset(tip.dx - length * math.cos(angle + math.pi / 6), tip.dy - length * math.sin(angle + math.pi / 6));
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..lineTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _paintLetter(Canvas canvas, Size size, PaintingStyle style, Color color, double strokeWidth) {
    final painter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: size.shortestSide * 0.72,
          fontWeight: FontWeight.w900,
          fontFamily: 'Cairo',
          height: 1,
          foreground: Paint()
            ..style = style
            ..strokeWidth = strokeWidth
            ..strokeJoin = StrokeJoin.round
            ..color = color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = Offset((size.width - painter.width) / 2, (size.height - painter.height) / 2 + size.height * 0.03);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _LetterColoringPainter oldDelegate) {
    return oldDelegate.letter != letter || oldDelegate.dots.length != dots.length || oldDelegate.progress != progress;
  }
}
