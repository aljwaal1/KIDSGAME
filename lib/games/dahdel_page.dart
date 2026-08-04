import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class DahdelPage extends StatefulWidget {
  const DahdelPage({super.key});

  @override
  State<DahdelPage> createState() => _DahdelPageState();
}

class _DahdelPageState extends State<DahdelPage> {
  final math.Random _random = math.Random();
  final List<Color> _colors = const <Color>[Color(0xFFDC2626), Color(0xFF2563EB)];
  final List<int> _scores = <int>[0, 0];
  final List<Offset> _groundMarbles = <Offset>[];
  Timer? _botTimer;
  DateTime _lastRollSound = DateTime.fromMillisecondsSinceEpoch(0);

  bool _againstBot = true;
  bool _moving = false;
  int _player = 0;
  int _throws = 0;
  Offset _shot = const Offset(.5, .90);
  Offset _drag = Offset.zero;
  Offset? _dragStart;
  Size _fieldSize = Size.zero;
  String _message = 'اسحب الجلّ من الأسفل ثم اتركه';

  @override
  void initState() {
    super.initState();
    _seedGround();
  }

  @override
  void dispose() {
    _botTimer?.cancel();
    super.dispose();
  }

  void _seedGround() {
    _groundMarbles
      ..clear()
      ..add(const Offset(.5, .13));
  }

  void _reset() {
    _botTimer?.cancel();
    setState(() {
      _scores[0] = 0;
      _scores[1] = 0;
      _player = 0;
      _throws = 0;
      _moving = false;
      _shot = const Offset(.5, .90);
      _drag = Offset.zero;
      _dragStart = null;
      _message = 'اسحب الجلّ من الأسفل ثم اتركه';
      _seedGround();
    });
  }

  void _setMode(bool againstBot) {
    if (_againstBot == againstBot) return;
    _againstBot = againstBot;
    _reset();
  }

  void _panStart(DragStartDetails details) {
    if (_moving || (_againstBot && _player == 1)) return;
    _dragStart = details.localPosition;
    _drag = Offset.zero;
    setState(() => _message = 'اسحب باتجاه الحصى ثم اترك');
  }

  void _panUpdate(DragUpdateDetails details) {
    if (_dragStart == null || _moving) return;
    setState(() => _drag = details.localPosition - _dragStart!);
  }

  void _panEnd(DragEndDetails details) {
    if (_dragStart == null || _moving || _fieldSize.isEmpty) return;
    final gestureVelocity = Offset(
      details.velocity.pixelsPerSecond.dx / _fieldSize.width,
      details.velocity.pixelsPerSecond.dy / _fieldSize.height,
    );
    var velocity = gestureVelocity;
    if (velocity.distance < .35) {
      velocity = Offset(
        _drag.dx / _fieldSize.width * 4.2,
        _drag.dy / _fieldSize.height * 4.2,
      );
    }
    _dragStart = null;
    _drag = Offset.zero;
    if (velocity.dy > -.12) {
      setState(() => _message = 'اسحب الجلّ إلى الأعلى باتجاه الحصى');
      return;
    }
    _shoot(_limit(velocity, 2.35));
  }

  Offset _limit(Offset value, double maximum) {
    return value.distance > maximum ? value / value.distance * maximum : value;
  }

  Future<void> _shoot(Offset initialVelocity, {bool robot = false}) async {
    if (_moving) return;
    final throwingPlayer = _player;
    setState(() {
      _moving = true;
      _throws++;
      _message = '${robot ? 'الروبوت' : 'اللاعب ${throwingPlayer + 1}'} رمى الجلّ';
    });
    SoundService.instance.play('move.wav', volumeBoost: 1.6);

    var position = const Offset(.5, .90);
    var velocity = initialVelocity;
    var hit = false;
    for (var frame = 0; frame < 150; frame++) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
      if (!mounted) return;
      position += velocity * .016;
      velocity *= .982;
      if (velocity.distance > .12 && DateTime.now().difference(_lastRollSound).inMilliseconds > 230) {
        _lastRollSound = DateTime.now();
        SoundService.instance.play('move.wav', volumeBoost: 1.45);
      }
      if (position.dx < .035 || position.dx > .965) {
        velocity = Offset(-velocity.dx * .72, velocity.dy);
        position = Offset(position.dx.clamp(.035, .965), position.dy);
      }
      if (position.dy < .05) {
        velocity = Offset(velocity.dx, -velocity.dy * .62);
        position = Offset(position.dx, .05);
      }
      if (position.dy > .95) {
        velocity = Offset(velocity.dx, -velocity.dy * .52);
        position = Offset(position.dx, .95);
      }
      hit = _groundMarbles.any((marble) => (marble - position).distance < .058);
      setState(() => _shot = position);
      if (hit || velocity.distance < .055) break;
    }

    if (!mounted) return;
    if (hit) {
      final captured = _groundMarbles.length;
      setState(() {
        _scores[throwingPlayer] += captured;
        _message = 'إصابة! جمع اللاعب ${throwingPlayer + 1} كل الجلول ($captured)';
        _seedGround();
      });
      HapticFeedback.heavyImpact();
      SoundService.instance.play('pop.wav', volumeBoost: 1.8);
      await Future<void>.delayed(const Duration(milliseconds: 150));
      SoundService.instance.play('win.wav', volumeBoost: 1.25);
      ScoreService.instance.addStars(2);
      await Future<void>.delayed(const Duration(milliseconds: 950));
    } else {
      setState(() {
        _groundMarbles.add(position);
        _message = 'لم يصب — بقي الجلّ على الأرض';
      });
      SoundService.instance.play('tap.wav');
      await Future<void>.delayed(const Duration(milliseconds: 650));
    }

    if (!mounted) return;
    setState(() {
      _shot = const Offset(.5, .90);
      _moving = false;
      _player = 1 - throwingPlayer;
      _message = _againstBot && _player == 1
          ? 'دور الروبوت…'
          : 'دور اللاعب ${_player + 1}: ارمِ جلّاً واحداً';
    });
    if (_againstBot && _player == 1) _scheduleBot();
  }

  void _scheduleBot() {
    _botTimer?.cancel();
    _botTimer = Timer(const Duration(milliseconds: 850), () {
      if (!mounted || _moving || _player != 1) return;
      final target = _groundMarbles[_random.nextInt(_groundMarbles.length)];
      final delta = target - const Offset(.5, .90);
      final error = Offset((_random.nextDouble() - .5) * .12, (_random.nextDouble() - .5) * .05);
      _shoot(_limit((delta + error) * 1.75, 1.8), robot: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الدحدل'),
        actions: <Widget>[IconButton(onPressed: _reset, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 7, 12, 12),
        child: Column(
          children: <Widget>[
            _DahdelHeader(message: _message, scores: _scores, player: _player, colors: _colors, throws: _throws),
            const SizedBox(height: 7),
            Row(children: <Widget>[
              Expanded(child: ChoiceChip(label: const Text('ضد الروبوت'), selected: _againstBot, onSelected: (_) => _setMode(true))),
              const SizedBox(width: 7),
              Expanded(child: ChoiceChip(label: const Text('مع صديق'), selected: !_againstBot, onSelected: (_) => _setMode(false))),
            ]),
            const SizedBox(height: 7),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  _fieldSize = Size(constraints.maxWidth, constraints.maxHeight);
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanStart: _panStart,
                    onPanUpdate: _panUpdate,
                    onPanEnd: _panEnd,
                    child: CustomPaint(
                      painter: _DahdelPainter(
                        groundMarbles: _groundMarbles,
                        shot: _shot,
                        drag: _drag,
                        playerColor: _colors[_player],
                        moving: _moving,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 7),
            const _DahdelRules(),
          ],
        ),
      ),
    );
  }
}

class _DahdelHeader extends StatelessWidget {
  const _DahdelHeader({required this.message, required this.scores, required this.player, required this.colors, required this.throws});
  final String message;
  final List<int> scores;
  final int player;
  final List<Color> colors;
  final int throws;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: <Color>[Color(0xFF0F766E), Color(0xFF14B8A6)])),
      child: Row(children: <Widget>[
        Icon(Icons.circle, color: colors[player], size: 34),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text(message, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 15, fontWeight: FontWeight.w900, height: 1.3)),
          Text('الأحمر ${scores[0]}  •  الأزرق ${scores[1]}  •  الرميات $throws', style: const TextStyle(color: Color(0xFFCCFBF1), fontSize: 12, fontWeight: FontWeight.w800)),
        ])),
      ]),
    );
  }
}

class _DahdelPainter extends CustomPainter {
  const _DahdelPainter({required this.groundMarbles, required this.shot, required this.drag, required this.playerColor, required this.moving});
  final List<Offset> groundMarbles;
  final Offset shot;
  final Offset drag;
  final Color playerColor;
  final bool moving;

  Offset _point(Offset value, Size size) => Offset(value.dx * size.width, value.dy * size.height);

  @override
  void paint(Canvas canvas, Size size) {
    final field = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24));
    canvas.drawRRect(field, Paint()..shader = const LinearGradient(colors: <Color>[Color(0xFFF7E7C6), Color(0xFFE8C98F)]).createShader(Offset.zero & size));
    canvas.drawRRect(field, Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = const Color(0xFF92400E));
    final finishY = size.height * .075;
    final finishPaint = Paint()
      ..color = const Color(0xCC92400E)
      ..strokeWidth = 2.5;
    canvas.drawLine(Offset(size.width * .12, finishY), Offset(size.width * .88, finishY), finishPaint);
    for (var i = 0; i < 20; i++) {
      canvas.drawRect(
        Rect.fromLTWH(size.width * (.12 + i * .038), finishY - 5, size.width * .038, 5),
        Paint()..color = i.isEven ? const Color(0xFFFEF3C7) : const Color(0xFF92400E),
      );
    }
    for (var i = 0; i < 18; i++) {
      final x = (i * 73 % 101) / 101 * size.width;
      final y = (i * 47 % 97) / 97 * size.height;
      canvas.drawCircle(Offset(x, y), 1.4, Paint()..color = const Color(0x33854D0E));
    }
    for (var i = 0; i < groundMarbles.length; i++) {
      _marble(canvas, _point(groundMarbles[i], size), 9, i.isEven ? const Color(0xFF2563EB) : const Color(0xFFF59E0B));
    }
    final shotPoint = _point(shot, size);
    _marble(canvas, shotPoint, 9.5, playerColor);
    if (!moving && drag.distance > 4) {
      final end = shotPoint + drag;
      canvas.drawLine(shotPoint, end, Paint()..color = playerColor..strokeWidth = 4..strokeCap = StrokeCap.round);
      canvas.drawCircle(end, 6, Paint()..color = playerColor);
    }
  }

  void _marble(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(center + const Offset(2, 3), radius, Paint()..color = const Color(0x44000000));
    canvas.drawCircle(center, radius, Paint()..shader = RadialGradient(center: const Alignment(-.35, -.4), colors: <Color>[Colors.white, color, color.withAlpha(210)], stops: const <double>[0, .35, 1]).createShader(Rect.fromCircle(center: center, radius: radius)));
    canvas.drawCircle(center, radius, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.5..color = Colors.white.withAlpha(190));
  }

  @override
  bool shouldRepaint(covariant _DahdelPainter oldDelegate) => true;
}

class _DahdelRules extends StatelessWidget {
  const _DahdelRules();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(15), border: Border.all(color: const Color(0xFF5EEAD4))),
      child: const Row(children: <Widget>[
        Icon(Icons.info_rounded, color: Color(0xFF0F766E), size: 20),
        SizedBox(width: 6),
        Expanded(child: Text('كل لاعب يرمي جلّاً واحداً. إذا اصطدم بأي جلّ، يجمع كل الجلول الموجودة على الأرض.', style: TextStyle(color: Color(0xFF115E59), fontSize: 11, fontWeight: FontWeight.w900))),
      ]),
    );
  }
}
