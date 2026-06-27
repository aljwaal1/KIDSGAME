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
      if (_dots.length > 180) {
        _dots.removeAt(0);
      }
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
      appBar: AppBar(
        title: const Text('تلوين الحروف الكبيرة'),
        actions: <Widget>[
          IconButton(
            tooltip: 'إعادة التلوين',
            onPressed: _clear,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
        children: <Widget>[
          _Header(letter: _letter, progress: _progress),
          const SizedBox(height: 14),
          Card(
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(
              aspectRatio: 1,
              child: GestureDetector(
                onPanStart: (DragStartDetails details) {
                  SoundService.instance.play('move.wav');
                  _addDot(details.localPosition);
                },
                onPanUpdate: (DragUpdateDetails details) => _addDot(details.localPosition),
                child: CustomPaint(
                  painter: _LetterColoringPainter(
                    letter: _letter,
                    dots: List<_PaintDot>.from(_dots),
                    progress: _progress,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'مرّر إصبعك داخل الحرف الكبير حتى يمتلئ باللون. الفكرة تلوين وتدريب على شكل الحرف بدون ضغط أو تقييم صعب.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
          ),
          const SizedBox(height: 16),
          _ColorPicker(
            colors: _palette,
            selectedIndex: _colorIndex,
            onSelect: (int index) {
              setState(() => _colorIndex = index);
              SoundService.instance.play('click.wav');
            },
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _previousLetter,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('السابق'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _sayLetter,
                  icon: const Icon(Icons.volume_up_rounded),
                  label: Text(_letter),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _nextLetter,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('التالي'),
                ),
              ),
            ],
          ),
        ],
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF4F46E5), Color(0xFFEC4899)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(color: Color(0x334F46E5), blurRadius: 18, offset: Offset(0, 8)),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Text(
              letter,
              style: const TextStyle(
                color: Color(0xFF4F46E5),
                fontSize: 44,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'لوّن الحرف الكبير',
                  style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Changa'),
                ),
                const SizedBox(height: 6),
                Text('التقدم: $percent%', style: const TextStyle(color: Color(0xFFFFF7D6))),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 9,
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'اختر لون التلوين',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Changa'),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                for (var i = 0; i < colors.length; i++)
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => onSelect(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: selectedIndex == i ? 52 : 44,
                      height: selectedIndex == i ? 52 : 44,
                      decoration: BoxDecoration(
                        color: colors[i],
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedIndex == i ? const Color(0xFF111827) : Colors.white,
                          width: selectedIndex == i ? 4 : 3,
                        ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(color: colors[i].withAlpha(85), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                    ),
                  ),
              ],
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
    final background = Paint()..color = const Color(0xFFF8FAFC);
    canvas.drawRect(Offset.zero & size, background);

    final guidePaint = Paint()
      ..color = const Color(0xFFE0E7FF)
      ..strokeWidth = 2;
    for (var x = 0.0; x <= size.width; x += size.width / 6) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), guidePaint);
    }
    for (var y = 0.0; y <= size.height; y += size.height / 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), guidePaint);
    }

    for (final dot in dots) {
      final paint = Paint()..color = dot.color.withAlpha(210);
      canvas.drawCircle(dot.position, size.width * 0.045, paint);
      canvas.drawCircle(dot.position, size.width * 0.022, Paint()..color = Colors.white.withAlpha(120));
    }

    _paintLetter(canvas, size, PaintingStyle.fill, const Color(0x33FFFFFF), 0);
    _paintLetter(canvas, size, PaintingStyle.stroke, const Color(0xFF1E293B), 8);
    _paintLetter(canvas, size, PaintingStyle.stroke, const Color(0xFF94A3B8), 2);

    final starPaint = Paint()..color = const Color(0xFFFFD65C).withAlpha((progress * 255).round().clamp(50, 255).toInt());
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.12), 18 + 10 * progress, starPaint);
    final checkPainter = TextPainter(
      text: TextSpan(
        text: progress >= 0.92 ? '✓' : '★',
        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    checkPainter.paint(canvas, Offset(size.width * 0.88 - checkPainter.width / 2, size.height * 0.12 - checkPainter.height / 2));
  }

  void _paintLetter(Canvas canvas, Size size, PaintingStyle style, Color color, double strokeWidth) {
    final painter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: size.width * 0.72,
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
