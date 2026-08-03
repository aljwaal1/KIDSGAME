import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

enum _SevenPhase { throwBall, rebuild, won, lost }

class SevenStonesPage extends StatefulWidget {
  const SevenStonesPage({super.key});

  @override
  State<SevenStonesPage> createState() => _SevenStonesPageState();
}

class _SevenStonesPageState extends State<SevenStonesPage>
    with SingleTickerProviderStateMixin {
  final math.Random _random = math.Random();
  late final AnimationController _defenderBall;
  Timer? _countdownTimer;

  _SevenPhase _phase = _SevenPhase.throwBall;
  Offset _ball = const Offset(.5, .89);
  Offset _aim = Offset.zero;
  Offset? _dragStart;
  List<Offset> _scattered = <Offset>[];
  int _rebuilt = 0;
  int _seconds = 12;
  int _wins = 0;
  int _misses = 0;

  @override
  void initState() {
    super.initState();
    _defenderBall = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _defenderBall.dispose();
    super.dispose();
  }

  void _reset() {
    _countdownTimer?.cancel();
    _defenderBall.stop();
    setState(() {
      _phase = _SevenPhase.throwBall;
      _ball = const Offset(.5, .89);
      _aim = Offset.zero;
      _dragStart = null;
      _scattered = <Offset>[];
      _rebuilt = 0;
      _seconds = 12;
    });
    SoundService.instance.play('click.wav');
  }

  void _panStart(DragStartDetails details) {
    if (_phase != _SevenPhase.throwBall) return;
    _dragStart = details.localPosition;
    _aim = Offset.zero;
  }

  void _panUpdate(DragUpdateDetails details) {
    if (_dragStart == null || _phase != _SevenPhase.throwBall) return;
    setState(() => _aim = details.localPosition - _dragStart!);
  }

  void _panEnd(DragEndDetails details, Size size) {
    if (_dragStart == null || _phase != _SevenPhase.throwBall) return;
    final start = _dragStart!;
    final end = start + _aim;
    _dragStart = null;
    _aim = Offset.zero;
    final direction = Offset(
      (end.dx - start.dx) / size.width,
      (end.dy - start.dy) / size.height,
    );
    if (direction.dy > -.08) {
      setState(() {});
      return;
    }
    _throwAtTower(direction);
  }

  Future<void> _throwAtTower(Offset direction) async {
    final start = const Offset(.5, .89);
    final normalized = direction / direction.distance;
    final end = start + normalized * .73;
    SoundService.instance.play('move.wav');
    for (var frame = 1; frame <= 24; frame++) {
      await Future<void>.delayed(const Duration(milliseconds: 18));
      if (!mounted) return;
      final t = Curves.easeOut.transform(frame / 24);
      setState(() => _ball = Offset.lerp(start, end, t)!);
    }
    final hit = (_ball - const Offset(.5, .25)).distance < .17;
    if (!hit) {
      _misses++;
      SoundService.instance.play('wrong.wav');
      await Future<void>.delayed(const Duration(milliseconds: 600));
      if (mounted) _reset();
      return;
    }
    HapticFeedback.heavyImpact();
    SoundService.instance.play('pop.wav');
    _startRebuild();
  }

  void _startRebuild() {
    final positions = <Offset>[
      const Offset(.18, .36),
      const Offset(.42, .40),
      const Offset(.74, .35),
      const Offset(.27, .57),
      const Offset(.65, .58),
      const Offset(.17, .75),
      const Offset(.78, .74),
    ]..shuffle(_random);
    setState(() {
      _phase = _SevenPhase.rebuild;
      _scattered = positions;
      _rebuilt = 0;
      _seconds = 12;
      _ball = const Offset(.08, .90);
    });
    _defenderBall.repeat(reverse: true);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _phase != _SevenPhase.rebuild) {
        timer.cancel();
        return;
      }
      setState(() => _seconds--);
      if (_seconds <= 0) {
        timer.cancel();
        _defenderBall.stop();
        setState(() {
          _phase = _SevenPhase.lost;
          _misses++;
        });
        SoundService.instance.play('wrong.wav');
      }
    });
  }

  void _tapStone(int index) {
    if (_phase != _SevenPhase.rebuild || index >= _scattered.length) return;
    setState(() {
      _scattered.removeAt(index);
      _rebuilt++;
    });
    HapticFeedback.selectionClick();
    SoundService.instance.play('tap.wav');
    if (_rebuilt == 7) _completeTower();
  }

  Future<void> _completeTower() async {
    _countdownTimer?.cancel();
    _defenderBall.stop();
    setState(() {
      _phase = _SevenPhase.won;
      _wins++;
    });
    await ScoreService.instance.addStars(3);
    await SoundService.instance.play('win.wav');
  }

  String get _title {
    switch (_phase) {
      case _SevenPhase.throwBall:
        return '1 ـ ارمِ الطابة لإسقاط الحجارة';
      case _SevenPhase.rebuild:
        return '2 ـ ابنِ البرج قبل وصول المدافع';
      case _SevenPhase.won:
        return 'نجحت! أعدت بناء الحجارة السبع';
      case _SevenPhase.lost:
        return 'انتهى الوقت قبل بناء البرج';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('سبع حجارة'),
        actions: <Widget>[IconButton(onPressed: _reset, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 7, 12, 12),
        child: Column(
          children: <Widget>[
            _SevenHeader(title: _title, phase: _phase, rebuilt: _rebuilt, seconds: _seconds, wins: _wins, misses: _misses),
            const SizedBox(height: 7),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: _panStart,
                    onPanUpdate: _panUpdate,
                    onPanEnd: (details) => _panEnd(details, size),
                    onTapUp: (details) {
                      if (_phase != _SevenPhase.rebuild) return;
                      for (var index = 0; index < _scattered.length; index++) {
                        final point = Offset(_scattered[index].dx * size.width, _scattered[index].dy * size.height);
                        if ((point - details.localPosition).distance < 35) {
                          _tapStone(index);
                          return;
                        }
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _defenderBall,
                      builder: (context, _) => CustomPaint(
                        painter: _SevenPainter(
                          phase: _phase,
                          ball: _ball,
                          aim: _aim,
                          scattered: _scattered,
                          rebuilt: _rebuilt,
                          defenderValue: _defenderBall.value,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 7),
            _SevenInstructions(phase: _phase, onRestart: _reset),
          ],
        ),
      ),
    );
  }
}

class _SevenHeader extends StatelessWidget {
  const _SevenHeader({required this.title, required this.phase, required this.rebuilt, required this.seconds, required this.wins, required this.misses});
  final String title;
  final _SevenPhase phase;
  final int rebuilt;
  final int seconds;
  final int wins;
  final int misses;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: <Color>[Color(0xFF78350F), Color(0xFFF97316)])),
      child: Row(children: <Widget>[
        const Icon(Icons.layers_rounded, color: Colors.white, size: 39),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 16, fontWeight: FontWeight.w900, height: 1.25)),
          Text(phase == _SevenPhase.rebuild ? 'تم بناء $rebuilt/7  •  الوقت $seconds' : 'الفوز $wins  •  المحاولات الفاشلة $misses', style: const TextStyle(color: Color(0xFFFFF7D6), fontSize: 12, fontWeight: FontWeight.w800)),
        ])),
      ]),
    );
  }
}

class _SevenPainter extends CustomPainter {
  const _SevenPainter({required this.phase, required this.ball, required this.aim, required this.scattered, required this.rebuilt, required this.defenderValue});
  final _SevenPhase phase;
  final Offset ball;
  final Offset aim;
  final List<Offset> scattered;
  final int rebuilt;
  final double defenderValue;

  Offset _point(Offset p, Size size) => Offset(p.dx * size.width, p.dy * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    final field = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24));
    canvas.drawRRect(field, Paint()..shader = const LinearGradient(colors: <Color>[Color(0xFF86EFAC), Color(0xFF22C55E)]).createShader(Offset.zero & size));
    canvas.drawRRect(field, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = const Color(0xFF15803D));
    canvas.drawOval(Rect.fromCenter(center: Offset(size.width * .5, size.height * .29), width: size.width * .40, height: size.height * .11), Paint()..color = const Color(0x33000000));

    if (phase == _SevenPhase.throwBall) {
      _tower(canvas, size, 7);
      final ballPoint = _point(ball, size);
      _ball(canvas, ballPoint, 22);
      if (aim.distance > 4) {
        canvas.drawLine(ballPoint, ballPoint + aim, Paint()..color = Colors.white..strokeWidth = 5..strokeCap = StrokeCap.round);
      }
    } else {
      for (var i = 0; i < scattered.length; i++) {
        _stone(canvas, _point(scattered[i], size), size.width * (.12 - (i % 3) * .008), 18, i);
      }
      _tower(canvas, size, rebuilt);
      final movingBall = Offset(size.width * (.08 + defenderValue * .84), size.height * .89);
      _ball(canvas, movingBall, 20);
      final label = TextPainter(text: const TextSpan(text: 'طابة المدافع', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)), textDirection: TextDirection.rtl)..layout();
      label.paint(canvas, movingBall + Offset(-label.width / 2, 24));
    }
  }

  void _tower(Canvas canvas, Size size, int count) {
    final centerX = size.width * .5;
    final baseY = size.height * .31;
    for (var i = 0; i < count; i++) {
      final width = size.width * (.27 - i * .016);
      _stone(canvas, Offset(centerX, baseY - i * 12), width, 14, i);
    }
  }

  void _stone(Canvas canvas, Offset center, double width, double height, int index) {
    final rect = Rect.fromCenter(center: center, width: width, height: height);
    final colors = <Color>[const Color(0xFF57534E), const Color(0xFF78716C), const Color(0xFFA8A29E)];
    canvas.drawRRect(RRect.fromRectAndRadius(rect.translate(2, 3), const Radius.circular(9)), Paint()..color = const Color(0x44000000));
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(9)), Paint()..color = colors[index % colors.length]);
    canvas.drawLine(rect.topLeft + const Offset(8, 3), rect.topRight - const Offset(8, -3), Paint()..color = Colors.white.withAlpha(80)..strokeWidth = 2);
  }

  void _ball(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center + const Offset(3, 4), radius, Paint()..color = const Color(0x44000000));
    canvas.drawCircle(center, radius, Paint()..shader = const RadialGradient(center: Alignment(-.35, -.35), colors: <Color>[Colors.white, Color(0xFFEF4444), Color(0xFF991B1B)], stops: <double>[0, .32, 1]).createShader(Rect.fromCircle(center: center, radius: radius)));
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius * .72), 0, math.pi, false, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant _SevenPainter oldDelegate) => true;
}

class _SevenInstructions extends StatelessWidget {
  const _SevenInstructions({required this.phase, required this.onRestart});
  final _SevenPhase phase;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final finished = phase == _SevenPhase.won || phase == _SevenPhase.lost;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFFF59E0B))),
      child: finished
          ? FilledButton.icon(onPressed: onRestart, icon: const Icon(Icons.replay_rounded), label: const Text('جولة جديدة'))
          : Row(children: <Widget>[
              Icon(phase == _SevenPhase.throwBall ? Icons.sports_baseball_rounded : Icons.touch_app_rounded, color: const Color(0xFFEA580C)),
              const SizedBox(width: 7),
              Expanded(child: Text(phase == _SevenPhase.throwBall ? 'اسحب الطابة من الأسفل نحو برج الحجارة السبع.' : 'اضغط الحجارة المتناثرة واحدةً واحدةً لإعادة بناء البرج قبل انتهاء الوقت.', style: const TextStyle(color: Color(0xFF7C2D12), fontSize: 11, fontWeight: FontWeight.w900))),
            ]),
    );
  }
}
