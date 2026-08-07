import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class ArabicLetterColoringPage extends StatefulWidget {
  const ArabicLetterColoringPage({super.key});

  @override
  State<ArabicLetterColoringPage> createState() => _ArabicLetterColoringPageState();
}

class _ArabicLetterColoringPageState extends State<ArabicLetterColoringPage> {
  static const List<String> _letters = <String>[
    'أ','ب','ت','ث','ج','ح','خ','د','ذ','ر','ز','س','ش','ص','ض','ط','ظ','ع','غ','ف','ق','ك','ل','م','ن','ه','و','ي',
  ];

  static const Map<String, String> _letterNames = <String, String>{
    'أ': 'أَلِف', 'ب': 'بَاء', 'ت': 'تَاء', 'ث': 'ثَاء', 'ج': 'جِيم',
    'ح': 'حَاء', 'خ': 'خَاء', 'د': 'دَال', 'ذ': 'ذَال', 'ر': 'رَاء',
    'ز': 'زَاي', 'س': 'سِين', 'ش': 'شِين', 'ص': 'صَاد', 'ض': 'ضَاد',
    'ط': 'طَاء', 'ظ': 'ظَاء', 'ع': 'عَيْن', 'غ': 'غَيْن', 'ف': 'فَاء',
    'ق': 'قَاف', 'ك': 'كَاف', 'ل': 'لَام', 'م': 'مِيم', 'ن': 'نُون',
    'ه': 'هَاء', 'و': 'وَاو', 'ي': 'يَاء',
  };

  static const List<Color> _colors = <Color>[
    Color(0xFFEC4899),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFF22C55E),
    Color(0xFFF97316),
    Color(0xFFFACC15),
  ];

  final FlutterTts _tts = FlutterTts();
  final List<_PaintStroke> _strokes = <_PaintStroke>[];
  int _letterIndex = 0;
  int _colorIndex = 0;
  double _paintAmount = 0;
  bool _completed = false;
  bool _voiceDisposed = false;
  String _voiceLanguage = 'ar-SA';
  Offset? _lastPoint;

  String get _letter => _letters[_letterIndex];
  String get _letterName => _letterNames[_letter] ?? _letter;
  Color get _selectedColor => _colors[_colorIndex];

  @override
  void initState() {
    super.initState();
    unawaited(_prepareVoice());
  }

  Future<void> _prepareVoice() async {
    try {
      final dynamic rawLanguages = await _tts.getLanguages;
      final languages = rawLanguages is List
          ? rawLanguages.map((value) => value.toString()).toList()
          : const <String>[];
      _voiceLanguage = <String>['ar-SA', 'ar', 'ar-EG', 'ar-AE'].firstWhere(
        (candidate) => languages.any((available) => available.toLowerCase() == candidate.toLowerCase()),
        orElse: () => 'ar-SA',
      );
      await _tts.setLanguage(_voiceLanguage);
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      await _speakLetter();
    } catch (error) {
      debugPrint('تعذر إعداد نطق تلوين الحروف العربية: $error');
    }
  }

  double get _voiceVolume {
    switch (SoundService.instance.levelNotifier.value) {
      case SoundLevel.high:
      case SoundLevel.medium:
        return 1.0;
      case SoundLevel.low:
        return 0.72;
      case SoundLevel.muted:
        return 0.0;
    }
  }

  Future<void> _speakLetter({Duration? delay}) async {
    if (_voiceDisposed || _voiceVolume == 0) return;
    if (delay != null) await Future<void>.delayed(delay);
    if (_voiceDisposed || _voiceVolume == 0) return;
    try {
      await _tts.stop();
      await _tts.setLanguage(_voiceLanguage);
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      await _tts.setVolume(_voiceVolume);
      await _tts.speak(_letterName);
    } catch (error) {
      debugPrint('تعذر نطق الحرف $_letterName: $error');
    }
  }

  void _startStroke(Offset point) {
    if (_completed) return;
    _lastPoint = point;
    setState(() {
      _strokes.add(_PaintStroke(_selectedColor, <Offset>[point]));
    });
  }

  void _continueStroke(Offset point, Size size) {
    if (_completed || _strokes.isEmpty) return;
    final previous = _lastPoint;
    _lastPoint = point;
    final delta = previous == null ? 0.0 : (point - previous).distance;
    setState(() {
      _strokes.last.points.add(point);
      _paintAmount += delta / math.max(1.0, size.shortestSide * 6.2);
    });
    if (_paintAmount >= 0.92 && !_completed) {
      _completeLetter();
    }
  }

  void _endStroke() {
    _lastPoint = null;
  }

  void _completeLetter() {
    if (_completed) return;
    setState(() {
      _completed = true;
      _paintAmount = 1.0;
    });
    ScoreService.instance.addStars(2);
    SoundService.instance.play('win.wav');
    unawaited(_speakLetter(delay: const Duration(milliseconds: 420)));
  }

  void _clear() {
    setState(() {
      _strokes.clear();
      _paintAmount = 0;
      _completed = false;
      _lastPoint = null;
    });
    SoundService.instance.play('click.wav');
  }

  void _next() {
    setState(() {
      _letterIndex = (_letterIndex + 1) % _letters.length;
      _strokes.clear();
      _paintAmount = 0;
      _completed = false;
      _lastPoint = null;
    });
    SoundService.instance.play('chime.wav');
    unawaited(_speakLetter(delay: const Duration(milliseconds: 180)));
  }

  void _previous() {
    setState(() {
      _letterIndex = (_letterIndex - 1 + _letters.length) % _letters.length;
      _strokes.clear();
      _paintAmount = 0;
      _completed = false;
      _lastPoint = null;
    });
    SoundService.instance.play('click.wav');
    unawaited(_speakLetter(delay: const Duration(milliseconds: 140)));
  }

  @override
  void dispose() {
    _voiceDisposed = true;
    unawaited(_tts.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = (_paintAmount.clamp(0.0, 1.0) * 100).round();
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('تلوين الحروف العربية'),
        actions: <Widget>[
          IconButton(
            tooltip: 'مسح التلوين',
            onPressed: _clear,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
          child: Column(
            children: <Widget>[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[Color(0xFF0F766E), Color(0xFF06B6D4)],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Row(
                  children: <Widget>[
                    InkWell(
                      onTap: () => unawaited(_speakLetter()),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        width: 66,
                        height: 66,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Text(
                          _letter,
                          style: const TextStyle(
                            color: Color(0xFF0F766E),
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            _letterName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Changa',
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _completed ? 'أحسنت! اكتمل الحرف 🎉' : 'لوّن داخل شكل الحرف بإصبعك',
                            style: const TextStyle(color: Color(0xFFE6FFFB), fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 7),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: _paintAmount.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: const Color(0x55FFFFFF),
                              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD65C)),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text('$percent%', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final size = Size(constraints.maxWidth, constraints.maxHeight);
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanStart: (details) => _startStroke(details.localPosition),
                        onPanUpdate: (details) => _continueStroke(details.localPosition, size),
                        onPanEnd: (_) => _endStroke(),
                        onPanCancel: _endStroke,
                        child: CustomPaint(
                          size: size,
                          painter: _ArabicColoringPainter(
                            letter: _letter,
                            strokes: _strokes,
                            completed: _completed,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  child: Row(
                    children: <Widget>[
                      const Text('اللون', style: TextStyle(fontWeight: FontWeight.w900, fontFamily: 'Changa')),
                      const Spacer(),
                      for (var i = 0; i < _colors.length; i++)
                        Padding(
                          padding: const EdgeInsetsDirectional.only(start: 7),
                          child: InkWell(
                            onTap: () => setState(() => _colorIndex = i),
                            borderRadius: BorderRadius.circular(99),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              width: _colorIndex == i ? 38 : 32,
                              height: _colorIndex == i ? 38 : 32,
                              decoration: BoxDecoration(
                                color: _colors[i],
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _colorIndex == i ? const Color(0xFF0F172A) : Colors.white,
                                  width: _colorIndex == i ? 4 : 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _previous,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('السابق'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => unawaited(_speakLetter()),
                      icon: const Icon(Icons.volume_up_rounded),
                      label: Text(_letterName),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _next,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('التالي'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaintStroke {
  _PaintStroke(this.color, this.points);
  final Color color;
  final List<Offset> points;
}

class _ArabicColoringPainter extends CustomPainter {
  const _ArabicColoringPainter({
    required this.letter,
    required this.strokes,
    required this.completed,
  });

  final String letter;
  final List<_PaintStroke> strokes;
  final bool completed;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFF8FAFC));
    _drawBackground(canvas, size);

    final painter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: size.shortestSide * 0.72,
          fontWeight: FontWeight.w900,
          fontFamily: 'Cairo',
          height: 1,
          color: const Color(0xFFDDE4EC),
          shadows: const <Shadow>[
            Shadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width * .92);

    final letterOffset = Offset(
      (size.width - painter.width) / 2,
      (size.height - painter.height) / 2,
    );
    painter.paint(canvas, letterOffset);

    final layerBounds = Offset.zero & size;
    canvas.saveLayer(layerBounds, Paint());

    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = size.shortestSide * .105
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
      if (stroke.points.length == 1) {
        canvas.drawCircle(stroke.points.first, paint.strokeWidth / 2, Paint()..color = stroke.color);
      } else {
        final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (var i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }

    final maskPainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: size.shortestSide * 0.72,
          fontWeight: FontWeight.w900,
          fontFamily: 'Cairo',
          height: 1,
          color: Colors.white,
        ),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width * .92);

    final maskPaint = Paint()..blendMode = BlendMode.dstIn;
    canvas.saveLayer(layerBounds, maskPaint);
    maskPainter.paint(canvas, letterOffset);
    canvas.restore();
    canvas.restore();

    final outlinePainter = TextPainter(
      text: TextSpan(
        text: letter,
        style: TextStyle(
          fontSize: size.shortestSide * 0.72,
          fontWeight: FontWeight.w900,
          fontFamily: 'Cairo',
          height: 1,
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = completed ? 4 : 3
            ..color = completed ? const Color(0xFF16A34A) : const Color(0xFF64748B),
        ),
      ),
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width * .92);
    outlinePainter.paint(canvas, letterOffset);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    for (var x = size.width / 6; x < size.width; x += size.width / 6) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (var y = size.height / 6; y < size.height; y += size.height / 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
  }

  @override
  bool shouldRepaint(covariant _ArabicColoringPainter oldDelegate) => true;
}
