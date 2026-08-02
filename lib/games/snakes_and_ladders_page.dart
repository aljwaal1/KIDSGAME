import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/game_header.dart';

class SnakesAndLaddersPage extends StatefulWidget {
  const SnakesAndLaddersPage({super.key});
  @override
  State<SnakesAndLaddersPage> createState() => _SnakesAndLaddersPageState();
}

class _SnakesAndLaddersPageState extends State<SnakesAndLaddersPage> {
  static const ladders = <int, int>{3: 22, 8: 30, 20: 41, 28: 55, 50: 67, 71: 92, 80: 99};
  static const snakes = <int, int>{98: 78, 95: 56, 88: 24, 62: 18, 48: 26, 36: 6};
  static const colors = <Color>[Color(0xFFEF4444), Color(0xFF2563EB), Color(0xFF16A34A), Color(0xFFF59E0B)];
  final random = Random();
  final confettiKey = GlobalKey<ConfettiOverlayState>();
  Timer? botTimer;
  int playerCount = 2, player = 0, dice = 1;
  bool botMode = false;
  int? winner;
  bool rolling = false;
  String event = 'اضغط على النرد لبدء السباق';
  late List<int> positions;

  @override
  void initState() { super.initState(); _reset(); }
  void _reset() {
    botTimer?.cancel();
    positions = List<int>.filled(playerCount, 1);
    setState(() { player = 0; dice = 1; winner = null; rolling = false; event = 'اضغط على النرد لبدء السباق'; });
  }
  void _setBotMode(bool value) {
    if (botMode == value) return;
    SoundService.instance.play('click.wav');
    botMode = value;
    _reset();
  }
  void _setPlayers(int value) {
    if (value == playerCount) return;
    SoundService.instance.play('click.wav');
    playerCount = value;
    _reset();
  }

  Future<void> _roll({bool fromBot = false}) async {
    if (rolling || winner != null || botMode && player > 0 && !fromBot) return;
    setState(() { rolling = true; event = 'النرد يدور...'; });
    SoundService.instance.play('click.wav');
    for (var i = 0; i < 6; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 65));
      if (!mounted) return;
      setState(() => dice = random.nextInt(6) + 1);
    }
    final turn = player;
    var target = positions[turn] + dice;
    var text = 'تقدم اللاعب ${turn + 1} $dice خطوات';
    if (target > 100) {
      target = positions[turn];
      text = 'تحتاج رقمًا مناسبًا للوصول إلى 100';
    } else if (ladders.containsKey(target)) {
      final start = target;
      target = ladders[target]!;
      text = 'سلم رائع! صعد اللاعب ${turn + 1} من $start إلى $target 🪜';
      SoundService.instance.play('chime.wav');
    } else if (snakes.containsKey(target)) {
      final start = target;
      target = snakes[target]!;
      text = 'أعاد الثعبان اللاعب ${turn + 1} من $start إلى $target 🐍';
      SoundService.instance.play('wrong.wav');
    } else {
      SoundService.instance.play('move.wav');
    }
    if (!mounted) return;
    setState(() {
      positions[turn] = target;
      rolling = false;
      event = text;
      if (target == 100) {
        winner = turn;
        event = 'فاز اللاعب ${turn + 1} بالسباق 🎉';
        SoundService.instance.play('win.wav');
        HapticFeedback.heavyImpact();
        confettiKey.currentState?.burst(count: 34);
        ScoreService.instance.addStars(4);
      } else if (dice == 6) {
        event = '$text — حصل على دور إضافي!';
      } else {
        player = (player + 1) % playerCount;
      }
    });
    _scheduleBot();
  }

  void _scheduleBot() {
    botTimer?.cancel();
    if (!botMode || winner != null || player == 0 || rolling) return;
    botTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted && winner == null && player > 0 && !rolling) _roll(fromBot: true);
    });
  }

  @override
  void dispose() { botTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final subtitle = winner == null ? 'دور اللاعب ${player + 1} — $event' : event;
    return ConfettiOverlay(
      key: confettiKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(children: <Widget>[
          GameHeader(title: 'السلم والثعبان', subtitle: subtitle, color: const Color(0xFF16A34A), onReset: _reset),
          const SizedBox(height: 6),
          Row(children: <Widget>[
            Expanded(child: ChoiceChip(label: const Text('مع الأصدقاء'), selected: !botMode, onSelected: (_) => _setBotMode(false))),
            const SizedBox(width: 8),
            Expanded(child: ChoiceChip(label: const Text('ضد الروبوت'), selected: botMode, onSelected: (_) => _setBotMode(true))),
          ]),
          const SizedBox(height: 5),
          Row(children: <Widget>[
            const Text('اللاعبون:', style: TextStyle(fontWeight: FontWeight.w800)),
            for (var count = 2; count <= 4; count++) Padding(
              padding: const EdgeInsetsDirectional.only(start: 4),
              child: ChoiceChip(label: Text('$count'), selected: playerCount == count, onSelected: (_) => _setPlayers(count)),
            ),
            const Spacer(),
            for (var i = 0; i < playerCount; i++) Container(
              width: player == i && winner == null ? 18 : 14, height: player == i && winner == null ? 18 : 14,
              margin: const EdgeInsetsDirectional.only(start: 4),
              decoration: BoxDecoration(shape: BoxShape.circle, color: colors[i], border: Border.all(color: Colors.white, width: 2)),
            ),
          ]),
          const SizedBox(height: 6),
          Expanded(child: Center(child: AspectRatio(aspectRatio: 1, child: CustomPaint(painter: _BoardPainter(positions, playerCount))))),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: rolling || winner != null || botMode && player > 0 ? null : () => _roll(),
            icon: AnimatedRotation(turns: rolling ? 1 : 0, duration: const Duration(milliseconds: 350), child: const Icon(Icons.casino_rounded, size: 28)),
            label: Text(rolling ? 'يدور...' : 'ارمِ النرد  $dice', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            style: FilledButton.styleFrom(backgroundColor: colors[player], minimumSize: const Size(190, 50)),
          ),
        ]),
      ),
    );
  }
}

class _BoardPainter extends CustomPainter {
  const _BoardPainter(this.positions, this.playerCount);
  final List<int> positions;
  final int playerCount;
  static const ladders = <int, int>{3: 22, 8: 30, 20: 41, 28: 55, 50: 67, 71: 92, 80: 99};
  static const snakes = <int, int>{98: 78, 95: 56, 88: 24, 62: 18, 48: 26, 36: 6};
  static const colors = <Color>[Color(0xFFEF4444), Color(0xFF2563EB), Color(0xFF16A34A), Color(0xFFF59E0B)];
  Offset _center(int square, double cell) {
    final zero = square - 1, logicalRow = zero ~/ 10, inRow = zero % 10;
    final column = logicalRow.isEven ? inRow : 9 - inRow;
    return Offset((column + .5) * cell, (9 - logicalRow + .5) * cell);
  }
  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 10;
    final border = Paint()..color = const Color(0x3356472C)..style = PaintingStyle.stroke..strokeWidth = 1;
    const cellColors = <Color>[Color(0xFFFFF3C4), Color(0xFFD9F99D)];
    for (var number = 1; number <= 100; number++) {
      final rect = Rect.fromCenter(center: _center(number, cell), width: cell, height: cell);
      canvas.drawRect(rect, Paint()..color = cellColors[(number + number ~/ 10) % 2]);
      canvas.drawRect(rect, border);
      final tp = TextPainter(text: TextSpan(text: '$number', style: TextStyle(color: const Color(0xFF475569), fontSize: cell * .24, fontWeight: FontWeight.w700)), textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, rect.topLeft + const Offset(2, 1));
    }
    final ladderPaint = Paint()..color = const Color(0xFF8B5A2B)..strokeWidth = cell * .11..strokeCap = StrokeCap.round;
    for (final x in ladders.entries) {
      final a = _center(x.key, cell), b = _center(x.value, cell), d = b - a, length = d.distance;
      final unit = d / length, normal = Offset(-unit.dy, unit.dx) * cell * .13;
      canvas.drawLine(a - normal, b - normal, ladderPaint);
      canvas.drawLine(a + normal, b + normal, ladderPaint);
      for (var distance = cell * .3; distance < length; distance += cell * .45) {
        final p = a + unit * distance;
        canvas.drawLine(p - normal, p + normal, ladderPaint..strokeWidth = cell * .06);
      }
      ladderPaint.strokeWidth = cell * .11;
    }
    var i = 0;
    for (final x in snakes.entries) {
      final a = _center(x.key, cell), b = _center(x.value, cell);
      final paint = Paint()
        ..color = i.isEven ? const Color(0xFFEF4444) : const Color(0xFF7C3AED)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cell * .16
        ..strokeCap = StrokeCap.round;
      final mid = Offset((a.dx + b.dx) / 2 + (i.isEven ? cell : -cell), (a.dy + b.dy) / 2);
      canvas.drawPath(Path()..moveTo(a.dx, a.dy)..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy), paint);
      canvas.drawCircle(a, cell * .16, Paint()..color = paint.color);
      i++;
    }
    const offsets = <Offset>[Offset(-.18, -.18), Offset(.18, -.18), Offset(-.18, .18), Offset(.18, .18)];
    for (var p = 0; p < playerCount; p++) {
      final center = _center(positions[p], cell) + offsets[p] * cell;
      canvas.drawCircle(center, cell * .18, Paint()..color = Colors.white);
      canvas.drawCircle(center, cell * .14, Paint()..color = colors[p]);
    }
  }
  @override
  bool shouldRepaint(covariant _BoardPainter oldDelegate) => true;
}