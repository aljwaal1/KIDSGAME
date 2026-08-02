import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/game_header.dart';

class DotsAndBoxesPage extends StatefulWidget {
  const DotsAndBoxesPage({super.key});
  @override
  State<DotsAndBoxesPage> createState() => _DotsAndBoxesPageState();
}

class _DotsAndBoxesPageState extends State<DotsAndBoxesPage> {
  static const int n = 4;
  static const colors = <Color>[Color(0xFFEF4444), Color(0xFF2563EB), Color(0xFF16A34A), Color(0xFFF59E0B)];
  final confettiKey = GlobalKey<ConfettiOverlayState>();
  final random = Random();
  Timer? botTimer;
  int playerCount = 2, player = 0;
  bool botMode = false;
  bool finished = false;
  late List<bool> h, v;
  late List<int> owners, scores;

  @override
  void initState() { super.initState(); _reset(); }

  void _reset() {
    botTimer?.cancel();
    h = List<bool>.filled((n + 1) * n, false);
    v = List<bool>.filled(n * (n + 1), false);
    owners = List<int>.filled(n * n, -1);
    scores = List<int>.filled(playerCount, 0);
    setState(() { player = 0; finished = false; });
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

  void _tap(TapDownDetails details, Size size) {
    if (finished || botMode && player > 0) return;
    final cell = size.width / n, p = details.localPosition;
    final hr = (p.dy / cell).round().clamp(0, n).toInt();
    final hc = (p.dx / cell).floor().clamp(0, n - 1).toInt();
    final vc = (p.dx / cell).round().clamp(0, n).toInt();
    final vr = (p.dy / cell).floor().clamp(0, n - 1).toInt();
    final hd = (p.dy - hr * cell).abs(), vd = (p.dx - vc * cell).abs();
    if (hd > cell * .28 && vd > cell * .28) return;
    _claim(hd <= vd, hd <= vd ? hr * n + hc : vr * (n + 1) + vc);
  }

  void _claim(bool horizontal, int index) {
    final edges = horizontal ? h : v;
    if (edges[index]) return;
    SoundService.instance.play('tap.wav');
    HapticFeedback.selectionClick();
    setState(() {
      edges[index] = true;
      var won = 0;
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          final i = r * n + c;
          if (owners[i] < 0 && h[r * n + c] && h[(r + 1) * n + c] && v[r * (n + 1) + c] && v[r * (n + 1) + c + 1]) {
            owners[i] = player;
            scores[player]++;
            won++;
          }
        }
      }
      if (owners.every((x) => x >= 0)) {
        finished = true;
        final best = scores.reduce((a, b) => a > b ? a : b);
        if (scores.where((x) => x == best).length == 1) {
          SoundService.instance.play('win.wav');
          confettiKey.currentState?.burst();
          ScoreService.instance.addStars(3);
        }
      } else if (won == 0) {
        player = (player + 1) % playerCount;
      } else {
        SoundService.instance.play('pop.wav');
      }
    });
    _scheduleBot();
  }

  void _scheduleBot() {
    botTimer?.cancel();
    if (!botMode || finished || player == 0) return;
    botTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted || finished || player == 0) return;
      final choices = <({bool horizontal, int index, int gain})>[];
      for (var i = 0; i < h.length; i++) if (!h[i]) choices.add((horizontal: true, index: i, gain: _edgeGain(true, i)));
      for (var i = 0; i < v.length; i++) if (!v[i]) choices.add((horizontal: false, index: i, gain: _edgeGain(false, i)));
      if (choices.isEmpty) return;
      final bestGain = choices.map((x) => x.gain).reduce(max);
      final best = choices.where((x) => x.gain == bestGain).toList();
      final choice = best[random.nextInt(best.length)];
      _claim(choice.horizontal, choice.index);
    });
  }

  int _edgeGain(bool horizontal, int index) {
    final edges = horizontal ? h : v;
    edges[index] = true;
    var gain = 0;
    for (var r = 0; r < n; r++) for (var c = 0; c < n; c++) {
      final i = r * n + c;
      if (owners[i] < 0 && h[r * n + c] && h[(r + 1) * n + c] && v[r * (n + 1) + c] && v[r * (n + 1) + c + 1]) gain++;
    }
    edges[index] = false;
    return gain;
  }

  String get message {
    if (!finished) return botMode && player > 0 ? 'الروبوت ${player + 1} يفكر...' : 'دور اللاعب ${player + 1} — أغلق مربعًا لتحصل على دور إضافي';
    final best = scores.reduce((a, b) => a > b ? a : b);
    final winners = <int>[for (var i = 0; i < scores.length; i++) if (scores[i] == best) i];
    return winners.length == 1 ? 'فاز اللاعب ${winners.first + 1} بـ $best مربعات 🎉' : 'انتهت الجولة بالتعادل';
  }

  @override
  void dispose() { botTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ConfettiOverlay(
    key: confettiKey,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(children: <Widget>[
        GameHeader(title: 'النقاط والمربعات', subtitle: message, color: const Color(0xFF7C3AED), onReset: _reset),
        const SizedBox(height: 8),
        Row(children: <Widget>[
          Expanded(child: ChoiceChip(label: const Text('مع الأصدقاء'), selected: !botMode, onSelected: (_) => _setBotMode(false))),
          const SizedBox(width: 8),
          Expanded(child: ChoiceChip(label: const Text('ضد الروبوت'), selected: botMode, onSelected: (_) => _setBotMode(true))),
        ]),
        const SizedBox(height: 6),
        Row(children: <Widget>[
          const Text('عدد اللاعبين:', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          for (var count = 2; count <= 4; count++) Padding(
            padding: const EdgeInsetsDirectional.only(start: 5),
            child: ChoiceChip(label: Text('$count'), selected: playerCount == count, onSelected: (_) => _setPlayers(count)),
          ),
        ]),
        const SizedBox(height: 8),
        Wrap(spacing: 7, runSpacing: 5, alignment: WrapAlignment.center, children: <Widget>[
          for (var i = 0; i < playerCount; i++) Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: colors[i].withAlpha(player == i && !finished ? 45 : 18), borderRadius: BorderRadius.circular(13), border: Border.all(color: colors[i], width: player == i && !finished ? 2.5 : 1)),
            child: Text('اللاعب ${i + 1}: ${scores[i]}', style: TextStyle(color: colors[i], fontWeight: FontWeight.w900)),
          ),
        ]),
        const SizedBox(height: 10),
        Expanded(child: Center(child: AspectRatio(aspectRatio: 1, child: LayoutBuilder(builder: (context, constraints) {
          final size = Size.square(constraints.maxWidth);
          return GestureDetector(behavior: HitTestBehavior.opaque, onTapDown: (d) => _tap(d, size), child: CustomPaint(size: size, painter: _DotsPainter(h, v, owners)));
        })))),
        const SizedBox(height: 6),
        const Text('اضغط بين نقطتين لرسم خط', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter(this.h, this.v, this.owners);
  final List<bool> h, v;
  final List<int> owners;
  static const colors = <Color>[Color(0xFFEF4444), Color(0xFF2563EB), Color(0xFF16A34A), Color(0xFFF59E0B)];
  @override
  void paint(Canvas canvas, Size size) {
    const n = 4;
    final cell = size.width / n;
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(24)), Paint()..color = const Color(0xFFF8FAFC));
    for (var r = 0; r < n; r++) for (var c = 0; c < n; c++) {
      final owner = owners[r * n + c];
      if (owner >= 0) canvas.drawRect(Rect.fromLTWH(c * cell + 5, r * cell + 5, cell - 10, cell - 10), Paint()..color = colors[owner].withAlpha(55));
    }
    final line = Paint()..color = const Color(0xFF334155)..strokeWidth = 8..strokeCap = StrokeCap.round;
    for (var r = 0; r <= n; r++) for (var c = 0; c < n; c++) if (h[r * n + c]) canvas.drawLine(Offset(c * cell, r * cell), Offset((c + 1) * cell, r * cell), line);
    for (var r = 0; r < n; r++) for (var c = 0; c <= n; c++) if (v[r * (n + 1) + c]) canvas.drawLine(Offset(c * cell, r * cell), Offset(c * cell, (r + 1) * cell), line);
    final dot = Paint()..color = const Color(0xFF0F172A);
    for (var r = 0; r <= n; r++) for (var c = 0; c <= n; c++) canvas.drawCircle(Offset(c * cell, r * cell), 8, dot);
  }
  @override
  bool shouldRepaint(covariant _DotsPainter oldDelegate) => true;
}