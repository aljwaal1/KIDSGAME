import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class CapitalLetterColoringPage extends StatefulWidget {
  const CapitalLetterColoringPage({super.key});

  @override
  State<CapitalLetterColoringPage> createState() => _CapitalLetterColoringPageState();
}

class _CapitalLetterColoringPageState extends State<CapitalLetterColoringPage> {
  static const List<String> letters = <String>[
    'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M',
    'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z',
  ];

  static const List<Color> colors = <Color>[
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFF22C55E),
    Color(0xFFF97316),
  ];

  int letterIndex = 0;
  int colorIndex = 0;
  double progress = 0;
  bool completed = false;
  final FlutterTts _letterVoice = FlutterTts();
  bool _voiceDisposed = false;

  String get letter => letters[letterIndex];
  Color get selectedColor => colors[colorIndex];

  @override
  void initState() {
    super.initState();
    unawaited(_prepareLetterVoice());
  }

  Future<void> _prepareLetterVoice() async {
    try {
      await _letterVoice.setLanguage('en-US');
      await _letterVoice.setSpeechRate(0.38);
      await _letterVoice.setPitch(1.0);
      await _letterVoice.awaitSpeakCompletion(true);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      await _sayLetterValue(letter);
    } catch (error) {
      debugPrint('تعذر إعداد نطق الحروف: $error');
    }
  }

  void _handleTrace(Offset point, Size size) {
    final hit = LetterTraceMath.hitProgress(letter, size, point);
    if (!hit.accepted) return;

    setState(() {
      progress = math.max(progress, hit.progress).clamp(0.0, 1.0).toDouble();
    });

    if (progress >= 0.92 && !completed) {
      completed = true;
      ScoreService.instance.addStars(2);
      SoundService.instance.play('win.wav');
      unawaited(_sayLetterValue(letter, afterCelebration: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('أحسنت! أتممت مسار حرف $letter')),
        );
      }
    }
  }

  void _reset() {
    setState(() {
      progress = 0;
      completed = false;
    });
    SoundService.instance.play('click.wav');
  }

  void _next() {
    setState(() {
      letterIndex = (letterIndex + 1) % letters.length;
      progress = 0;
      completed = false;
    });
    SoundService.instance.play('chime.wav');
    unawaited(_sayLetterValue(letter, delay: const Duration(milliseconds: 180)));
  }

  void _previous() {
    setState(() {
      letterIndex = (letterIndex - 1 + letters.length) % letters.length;
      progress = 0;
      completed = false;
    });
    SoundService.instance.play('click.wav');
    unawaited(_sayLetterValue(letter, delay: const Duration(milliseconds: 180)));
  }

  double get _voiceVolume {
    switch (SoundService.instance.levelNotifier.value) {
      case SoundLevel.high:
        return 1.0;
      case SoundLevel.medium:
        return 1.0;
      case SoundLevel.low:
        return 0.72;
      case SoundLevel.muted:
        return 0.0;
    }
  }

  Future<void> _sayLetterValue(String value, {bool afterCelebration = false, Duration? delay}) async {
    if (_voiceVolume == 0 || _voiceDisposed) return;
    if (delay != null) await Future<void>.delayed(delay);
    if (afterCelebration) {
      await Future<void>.delayed(const Duration(milliseconds: 320));
    }
    final volume = _voiceVolume;
    if (volume == 0 || _voiceDisposed) return;
    try {
      await _letterVoice.stop();
      await _letterVoice.setVolume(volume);
      await _letterVoice.speak(value);
    } catch (error) {
      debugPrint('تعذر نطق الحرف $value: $error');
    }
  }

  void _sayLetter() {
    unawaited(_sayLetterValue(letter));
  }

  @override
  void dispose() {
    _voiceDisposed = true;
    unawaited(_letterVoice.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('تلوين الحروف الكبيرة'),
        actions: <Widget>[
          IconButton(
            tooltip: 'إعادة المسار',
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Column(
            children: <Widget>[
              _Header(letter: letter, progress: progress),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (details) {
                          SoundService.instance.play('move.wav');
                          _handleTrace(details.localPosition, canvasSize);
                        },
                        onPanUpdate: (details) => _handleTrace(details.localPosition, canvasSize),
                        child: CustomPaint(
                          size: canvasSize,
                          painter: _TracePainter(
                            letter: letter,
                            progress: progress,
                            color: selectedColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _ColorPicker(
                colors: colors,
                selectedIndex: colorIndex,
                onSelect: (index) {
                  setState(() => colorIndex = index);
                  SoundService.instance.play('click.wav');
                },
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(child: OutlinedButton.icon(onPressed: _previous, icon: const Icon(Icons.arrow_back_rounded), label: const Text('السابق'))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton.icon(onPressed: _sayLetter, icon: const Icon(Icons.volume_up_rounded), label: Text(letter))),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton.icon(onPressed: _next, icon: const Icon(Icons.arrow_forward_rounded), label: const Text('التالي'))),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
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
                const Text('اتبع السهم داخل الحرف', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'Changa')),
                const SizedBox(height: 5),
                Text('امتلاء المسار: $percent%', style: const TextStyle(color: Color(0xFFFFF7D6))),
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
            const Text('لون المسار', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, fontFamily: 'Changa')),
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

class _TracePainter extends CustomPainter {
  const _TracePainter({required this.letter, required this.progress, required this.color});
  final String letter;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF8FAFC));
    _drawGrid(canvas, size);

    final path = LetterTraceMath.pathFor(letter, size);
    final basePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.09
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, basePaint);

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.095
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _drawPartial(canvas, path, progress, fillPaint);

    final shinePaint = Paint()
      ..color = Colors.white.withAlpha(170)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.024
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    _drawPartial(canvas, path, progress, shinePaint);

    _drawStartAndArrow(canvas, path, progress, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE0E7FF)
      ..strokeWidth = 1.4;
    for (var x = 0.0; x <= size.width; x += size.width / 5) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (var y = 0.0; y <= size.height; y += size.height / 5) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawPartial(Canvas canvas, Path path, double progress, Paint paint) {
    final total = LetterTraceMath.totalLength(path);
    if (total <= 0 || progress <= 0) return;
    var remaining = total * progress.clamp(0.0, 1.0).toDouble();
    for (final metric in path.computeMetrics()) {
      if (remaining <= 0) break;
      final length = math.min(metric.length, remaining);
      canvas.drawPath(metric.extractPath(0, length), paint);
      remaining -= length;
    }
  }

  void _drawStartAndArrow(Canvas canvas, Path path, double progress, Size size) {
    final total = LetterTraceMath.totalLength(path);
    if (total <= 0) return;
    final start = LetterTraceMath.pointAt(path, 0) ?? Offset(size.width * 0.30, size.height * 0.25);
    final arrow = LetterTraceMath.pointAndAngleAt(path, math.max(0.08, progress) * total);

    canvas.drawCircle(start, 14, Paint()..color = const Color(0xFF22C55E));
    final text = TextPainter(text: const TextSpan(text: 'ابدأ', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)), textDirection: TextDirection.rtl)..layout();
    text.paint(canvas, start.translate(-text.width / 2, -text.height / 2));

    if (arrow == null) return;
    final tip = arrow.position;
    canvas.drawCircle(tip, 20, Paint()..color = Colors.white.withAlpha(230));
    _drawArrowHead(canvas, tip, arrow.angle, progress >= 0.92 ? const Color(0xFF22C55E) : const Color(0xFFF59E0B));
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

  @override
  bool shouldRepaint(covariant _TracePainter oldDelegate) {
    return oldDelegate.letter != letter || oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class TraceHit {
  const TraceHit({required this.accepted, required this.progress});
  final bool accepted;
  final double progress;
}

class TracePoint {
  const TracePoint(this.position, this.angle);
  final Offset position;
  final double angle;
}

class LetterTraceMath {
  static Path pathFor(String letter, Size size) {
    final w = size.width;
    final h = size.height;
    switch (letter.toUpperCase()) {
      case 'A':
        return Path()..moveTo(w * .30, h * .78)..lineTo(w * .50, h * .18)..lineTo(w * .70, h * .78)..moveTo(w * .40, h * .55)..lineTo(w * .60, h * .55);
      case 'B':
        return Path()..moveTo(w * .35, h * .18)..lineTo(w * .35, h * .80)..moveTo(w * .35, h * .20)..quadraticBezierTo(w * .75, h * .24, w * .40, h * .50)..quadraticBezierTo(w * .78, h * .72, w * .35, h * .80);
      case 'C':
        return Path()..moveTo(w * .72, h * .25)..quadraticBezierTo(w * .30, h * .12, w * .28, h * .50)..quadraticBezierTo(w * .30, h * .86, w * .72, h * .74);
      case 'D':
        return Path()..moveTo(w * .35, h * .18)..lineTo(w * .35, h * .80)..moveTo(w * .35, h * .20)..quadraticBezierTo(w * .78, h * .32, w * .68, h * .55)..quadraticBezierTo(w * .62, h * .78, w * .35, h * .80);
      case 'E':
        return Path()..moveTo(w * .68, h * .20)..lineTo(w * .35, h * .20)..lineTo(w * .35, h * .80)..moveTo(w * .35, h * .50)..lineTo(w * .62, h * .50)..moveTo(w * .35, h * .80)..lineTo(w * .70, h * .80);
      case 'F':
        return Path()..moveTo(w * .68, h * .20)..lineTo(w * .35, h * .20)..lineTo(w * .35, h * .80)..moveTo(w * .35, h * .50)..lineTo(w * .62, h * .50);
      case 'G':
        return Path()..moveTo(w * .72, h * .25)..quadraticBezierTo(w * .28, h * .12, w * .28, h * .52)..quadraticBezierTo(w * .30, h * .88, w * .72, h * .74)..lineTo(w * .58, h * .58)..lineTo(w * .72, h * .58);
      case 'H':
        return Path()..moveTo(w * .32, h * .18)..lineTo(w * .32, h * .80)..moveTo(w * .68, h * .18)..lineTo(w * .68, h * .80)..moveTo(w * .32, h * .50)..lineTo(w * .68, h * .50);
      case 'I':
        return Path()..moveTo(w * .35, h * .20)..lineTo(w * .65, h * .20)..moveTo(w * .50, h * .20)..lineTo(w * .50, h * .80)..moveTo(w * .35, h * .80)..lineTo(w * .65, h * .80);
      case 'J':
        return Path()..moveTo(w * .35, h * .20)..lineTo(w * .68, h * .20)..moveTo(w * .58, h * .20)..lineTo(w * .58, h * .66)..quadraticBezierTo(w * .52, h * .84, w * .32, h * .72);
      case 'K':
        return Path()..moveTo(w * .35, h * .18)..lineTo(w * .35, h * .80)..moveTo(w * .70, h * .20)..lineTo(w * .35, h * .52)..lineTo(w * .72, h * .80);
      case 'L':
        return Path()..moveTo(w * .35, h * .18)..lineTo(w * .35, h * .80)..lineTo(w * .70, h * .80);
      case 'M':
        return Path()..moveTo(w * .25, h * .80)..lineTo(w * .25, h * .20)..lineTo(w * .50, h * .55)..lineTo(w * .75, h * .20)..lineTo(w * .75, h * .80);
      case 'N':
        return Path()..moveTo(w * .30, h * .80)..lineTo(w * .30, h * .20)..lineTo(w * .70, h * .80)..lineTo(w * .70, h * .20);
      case 'O':
        return Path()..moveTo(w * .50, h * .18)..quadraticBezierTo(w * .78, h * .20, w * .76, h * .52)..quadraticBezierTo(w * .72, h * .84, w * .50, h * .82)..quadraticBezierTo(w * .24, h * .80, w * .24, h * .50)..quadraticBezierTo(w * .24, h * .20, w * .50, h * .18);
      case 'P':
        return Path()..moveTo(w * .35, h * .80)..lineTo(w * .35, h * .20)..quadraticBezierTo(w * .78, h * .24, w * .62, h * .48)..quadraticBezierTo(w * .50, h * .58, w * .35, h * .52);
      case 'Q':
        return Path()..moveTo(w * .50, h * .18)..quadraticBezierTo(w * .78, h * .20, w * .76, h * .52)..quadraticBezierTo(w * .72, h * .84, w * .50, h * .82)..quadraticBezierTo(w * .24, h * .80, w * .24, h * .50)..quadraticBezierTo(w * .24, h * .20, w * .50, h * .18)..moveTo(w * .58, h * .62)..lineTo(w * .75, h * .82);
      case 'R':
        return Path()..moveTo(w * .35, h * .80)..lineTo(w * .35, h * .20)..quadraticBezierTo(w * .78, h * .24, w * .62, h * .48)..quadraticBezierTo(w * .50, h * .58, w * .35, h * .52)..lineTo(w * .72, h * .80);
      case 'S':
        return Path()..moveTo(w * .70, h * .25)..quadraticBezierTo(w * .34, h * .10, w * .32, h * .38)..quadraticBezierTo(w * .35, h * .56, w * .62, h * .55)..quadraticBezierTo(w * .82, h * .70, w * .55, h * .82)..quadraticBezierTo(w * .35, h * .88, w * .25, h * .72);
      case 'T':
        return Path()..moveTo(w * .28, h * .20)..lineTo(w * .72, h * .20)..moveTo(w * .50, h * .20)..lineTo(w * .50, h * .80);
      case 'U':
        return Path()..moveTo(w * .30, h * .20)..lineTo(w * .30, h * .62)..quadraticBezierTo(w * .32, h * .82, w * .50, h * .82)..quadraticBezierTo(w * .68, h * .82, w * .70, h * .62)..lineTo(w * .70, h * .20);
      case 'V':
        return Path()..moveTo(w * .25, h * .20)..lineTo(w * .50, h * .82)..lineTo(w * .75, h * .20);
      case 'W':
        return Path()..moveTo(w * .20, h * .20)..lineTo(w * .34, h * .82)..lineTo(w * .50, h * .52)..lineTo(w * .66, h * .82)..lineTo(w * .80, h * .20);
      case 'X':
        return Path()..moveTo(w * .28, h * .20)..lineTo(w * .72, h * .80)..moveTo(w * .72, h * .20)..lineTo(w * .28, h * .80);
      case 'Y':
        return Path()..moveTo(w * .28, h * .20)..lineTo(w * .50, h * .48)..lineTo(w * .72, h * .20)..moveTo(w * .50, h * .48)..lineTo(w * .50, h * .80);
      case 'Z':
        return Path()..moveTo(w * .28, h * .20)..lineTo(w * .72, h * .20)..lineTo(w * .28, h * .80)..lineTo(w * .72, h * .80);
      default:
        return Path()..moveTo(w * .30, h * .25)..lineTo(w * .70, h * .75);
    }
  }

  static TraceHit hitProgress(String letter, Size size, Offset point) {
    final path = pathFor(letter, size);
    final total = totalLength(path);
    if (total <= 0) return const TraceHit(accepted: false, progress: 0);

    var bestDistance = double.infinity;
    var bestProgress = 0.0;
    var consumed = 0.0;
    for (final metric in path.computeMetrics()) {
      final step = math.max(6.0, metric.length / 40).toDouble();
      for (var d = 0.0; d <= metric.length; d += step) {
        final tangent = metric.getTangentForOffset(d);
        if (tangent == null) continue;
        final distance = (tangent.position - point).distance;
        if (distance < bestDistance) {
          bestDistance = distance;
          bestProgress = (consumed + d) / total;
        }
      }
      consumed += metric.length;
    }

    final tolerance = size.shortestSide * 0.13;
    return TraceHit(accepted: bestDistance <= tolerance, progress: bestProgress.clamp(0.0, 1.0).toDouble());
  }

  static double totalLength(Path path) {
    var total = 0.0;
    for (final metric in path.computeMetrics()) {
      total += metric.length;
    }
    return total;
  }

  static Offset? pointAt(Path path, double distance) {
    final point = pointAndAngleAt(path, distance);
    return point?.position;
  }

  static TracePoint? pointAndAngleAt(Path path, double distance) {
    var remaining = distance;
    for (final metric in path.computeMetrics()) {
      if (remaining <= metric.length) {
        final tangent = metric.getTangentForOffset(remaining);
        if (tangent == null) return null;
        return TracePoint(tangent.position, tangent.angle);
      }
      remaining -= metric.length;
    }
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return null;
    final tangent = metrics.last.getTangentForOffset(metrics.last.length);
    if (tangent == null) return null;
    return TracePoint(tangent.position, tangent.angle);
  }
}
