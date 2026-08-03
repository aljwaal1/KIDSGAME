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
  late List<int> h, v;
  late List<int> owners, scores;

  @override
  void initState() { super.initState(); _reset(); }

  void _reset() {
    botTimer?.cancel();
    h = List<int>.filled((n + 1) * n, -1);
    v = List<int>.filled(n * (n + 1), -1);
    owners = List<int>.filled(n * n, -1);
    scores = List<int>.filled(playerCount, 0);
    setState(() { player = 0; finished = false; });
  }

  void _setBotMode(bool value) {
    if (botMode == value) return;
    SoundService.instance.play('click.wav');
    botMode = value;
    if (value) playerCount = 2;
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
    if (edges[index] >= 0) return;
    SoundService.instance.play('tap.wav');
    HapticFeedback.selectionClick();
    setState(() {
      edges[index] = player;
      var won = 0;
      for (var r = 0; r < n; r++) {
        for (var c = 0; c < n; c++) {
          final i = r * n + c;
          if (owners[i] < 0 && h[r * n + c] >= 0 && h[(r + 1) * n + c] >= 0 && v[r * (n + 1) + c] >= 0 && v[r * (n + 1) + c + 1] >= 0) {
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
      for (var i = 0; i < h.length; i++) if (h[i] < 0) choices.add((horizontal: true, index: i, gain: _edgeGain(true, i)));
      for (var i = 0; i < v.length; i++) if (v[i] < 0) choices.add((horizontal: false, index: i, gain: _edgeGain(false, i)));
      if (choices.isEmpty) return;
      final bestGain = choices.map((x) => x.gain).reduce(max);
      final best = choices.where((x) => x.gain == bestGain).toList();
      final choice = best[random.nextInt(best.length)];
      _claim(choice.horizontal, choice.index);
    });
  }

  int _edgeGain(bool horizontal, int index) {
    final edges = horizontal ? h : v;
    edges[index] = player;
    var gain = 0;
    for (var r = 0; r < n; r++) for (var c = 0; c < n; c++) {
      final i = r * n + c;
      if (owners[i] < 0 && h[r * n + c] >= 0 && h[(r + 1) * n + c] >= 0 && v[r * (n + 1) + c] >= 0 && v[r * (n + 1) + c + 1] >= 0) gain++;
    }
    edges[index] = -1;
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
  Widget build(BuildContext context) {
    return ConfettiOverlay(
      key: confettiKey,
      child: LayoutBuilder(builder: (context, page) {
        final boardSize = min(page.maxWidth - 52, 320.0).toDouble();
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 18),
          child: Column(children: <Widget>[
            GameHeader(title: 'النقاط والمربعات', subtitle: message, color: const Color(0xFF7C3AED), onReset: _reset),
            const SizedBox(height: 8),
            Row(children: <Widget>[
              Expanded(child: ChoiceChip(label: const Text('مع الأصدقاء'), selected: !botMode, onSelected: (_) => _setBotMode(false))),
              const SizedBox(width: 8),
              Expanded(child: ChoiceChip(label: const Text('ضد الروبوت'), selected: botMode, onSelected: (_) => _setBotMode(true))),
            ]),
            if (!botMode) ...<Widget>[
              const SizedBox(height: 6),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                const Text('عدد اللاعبين', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                const SizedBox(width: 6),
                for (var count = 2; count <= 4; count++) Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4),
                  child: ChoiceChip(
                    visualDensity: VisualDensity.compact,
                    label: Text('$count'),
                    selected: playerCount == count,
                    onSelected: (_) => _setPlayers(count),
                  ),
                ),
              ]),
            ],
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors[player].withAlpha(28),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: colors[player], width: 2),
              ),
              child: Row(children: <Widget>[
                Container(width: 14, height: 14, decoration: BoxDecoration(color: colors[player], shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Expanded(child: Text(botMode && player > 0 ? 'الروبوت يفكر الآن…' : 'الآن دور اللاعب ${player + 1} — اختر خطاً', style: TextStyle(color: colors[player], fontWeight: FontWeight.w900))),
              ]),
            ),
            const SizedBox(height: 7),
            Wrap(spacing: 7, runSpacing: 5, alignment: WrapAlignment.center, children: <Widget>[
              for (var i = 0; i < playerCount; i++) Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: colors[i].withAlpha(player == i && !finished ? 45 : 18), borderRadius: BorderRadius.circular(13), border: Border.all(color: colors[i], width: player == i && !finished ? 2.5 : 1)),
                child: Text('${botMode && i > 0 ? 'الروبوت' : 'اللاعب ${i + 1}'}: ${scores[i]} مربع', style: TextStyle(color: colors[i], fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ]),
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFC4B5FD), width: 3),
                boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x337C3AED), blurRadius: 16, offset: Offset(0, 8))],
              ),
              child: SizedBox(
                width: boardSize,
                height: boardSize,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) => _tap(details, Size.square(boardSize)),
                      child: CustomPaint(size: Size.square(boardSize), painter: _DotsPainter(h, v, owners)),
                    ),
                    if (h.every((edge) => edge < 0) && v.every((edge) => edge < 0))
                      IgnorePointer(
                        child: Align(
                          alignment: const Alignment(0, -0.82),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: const Color(0xEFFFFFFF), borderRadius: BorderRadius.circular(99), boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x33000000), blurRadius: 8)]),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
                              Icon(Icons.touch_app_rounded, color: Color(0xFF7C3AED), size: 18),
                              SizedBox(width: 5),
                              Text('ابدأ بلمس خط رمادي', style: TextStyle(color: Color(0xFF4C1D95), fontWeight: FontWeight.w900, fontSize: 12)),
                            ]),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            const _HowToPlayDots(),
            const SizedBox(height: 8),
          ]),
        );
      }),
    );
  }
}

class _DotsPainter extends CustomPainter {
  const _DotsPainter(this.h, this.v, this.owners);
  final List<int> h, v;
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
    final guide = Paint()..color = const Color(0xFFCBD5E1)..strokeWidth = 3..strokeCap = StrokeCap.round;
    for (var r = 0; r <= n; r++) for (var c = 0; c < n; c++) canvas.drawLine(Offset(c * cell + 13, r * cell), Offset((c + 1) * cell - 13, r * cell), guide);
    for (var r = 0; r < n; r++) for (var c = 0; c <= n; c++) canvas.drawLine(Offset(c * cell, r * cell + 13), Offset(c * cell, (r + 1) * cell - 13), guide);
    final line = Paint()..strokeWidth = 9..strokeCap = StrokeCap.round;
    for (var r = 0; r <= n; r++) for (var c = 0; c < n; c++) {
      final owner = h[r * n + c];
      if (owner >= 0) canvas.drawLine(Offset(c * cell, r * cell), Offset((c + 1) * cell, r * cell), line..color = colors[owner]);
    }
    for (var r = 0; r < n; r++) for (var c = 0; c <= n; c++) {
      final owner = v[r * (n + 1) + c];
      if (owner >= 0) canvas.drawLine(Offset(c * cell, r * cell), Offset(c * cell, (r + 1) * cell), line..color = colors[owner]);
    }
    final dot = Paint()..color = const Color(0xFF0F172A);
    for (var r = 0; r <= n; r++) for (var c = 0; c <= n; c++) canvas.drawCircle(Offset(c * cell, r * cell), 8, dot);
  }
  @override
  bool shouldRepaint(covariant _DotsPainter oldDelegate) => true;
}

class _HowToPlayDots extends StatelessWidget {
  const _HowToPlayDots();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(color: const Color(0xFFF5F3FF), borderRadius: BorderRadius.circular(16)),
      child: const Row(children: <Widget>[
        Expanded(child: _DotRule(icon: Icons.touch_app_rounded, number: '1', text: 'المس خطاً')),
        Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFA78BFA), size: 13),
        Expanded(child: _DotRule(icon: Icons.crop_square_rounded, number: '2', text: 'أغلق مربعاً')),
        Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFA78BFA), size: 13),
        Expanded(child: _DotRule(icon: Icons.emoji_events_rounded, number: '3', text: 'اجمع الأكثر')),
      ]),
    );
  }
}

class _DotRule extends StatelessWidget {
  const _DotRule({required this.icon, required this.number, required this.text});
  final IconData icon;
  final String number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
      Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
        Text(number, style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w900)),
        const SizedBox(width: 3),
        Icon(icon, color: const Color(0xFF7C3AED), size: 18),
      ]),
      Text(text, maxLines: 1, style: const TextStyle(color: Color(0xFF4C1D95), fontWeight: FontWeight.w800, fontSize: 11)),
    ]);
  }
}
