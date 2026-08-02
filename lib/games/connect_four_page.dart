import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/game_header.dart';

class ConnectFourPage extends StatefulWidget {
  const ConnectFourPage({super.key});
  @override
  State<ConnectFourPage> createState() => _ConnectFourPageState();
}

class _ConnectFourPageState extends State<ConnectFourPage> {
  static const rows = 6, columns = 7;
  static const colors = <Color>[Color(0xFFEF4444), Color(0xFFFACC15)];
  final confettiKey = GlobalKey<ConfettiOverlayState>();
  final random = Random();
  Timer? botTimer;
  late List<int> board;
  int player = 0;
  bool botMode = false;
  int? winner;
  bool draw = false;

  @override
  void initState() { super.initState(); _reset(); }
  void _reset() {
    botTimer?.cancel();
    board = List<int>.filled(rows * columns, -1);
    setState(() { player = 0; winner = null; draw = false; });
  }

  void _setBotMode(bool value) {
    if (botMode == value) return;
    SoundService.instance.play('click.wav');
    botMode = value;
    _reset();
  }

  void _drop(int column, {bool fromBot = false}) {
    if (winner != null || draw || botMode && player == 1 && !fromBot) return;
    var row = -1;
    for (var r = rows - 1; r >= 0; r--) if (board[r * columns + column] < 0) { row = r; break; }
    if (row < 0) { HapticFeedback.selectionClick(); return; }
    SoundService.instance.play('move.wav');
    HapticFeedback.lightImpact();
    setState(() {
      board[row * columns + column] = player;
      if (_won(row, column, player)) {
        winner = player;
        SoundService.instance.play('win.wav');
        HapticFeedback.heavyImpact();
        confettiKey.currentState?.burst();
        ScoreService.instance.addStars(3);
      } else if (!board.contains(-1)) {
        draw = true;
      } else {
        player = 1 - player;
      }
    });
    if (winner == null && !draw && botMode && player == 1) _scheduleBot();
  }

  void _scheduleBot() {
    botTimer?.cancel();
    botTimer = Timer(const Duration(milliseconds: 650), () {
      if (!mounted || winner != null || draw || player != 1) return;
      _drop(_chooseBotColumn(), fromBot: true);
    });
  }

  int _chooseBotColumn() {
    final available = <int>[for (var c = 0; c < columns; c++) if (board[c] < 0) c];
    for (final c in available) if (_wouldWin(c, 1)) return c;
    for (final c in available) if (_wouldWin(c, 0)) return c;
    if (available.contains(3)) return 3;
    available.shuffle(random);
    return available.first;
  }

  bool _wouldWin(int column, int value) {
    var row = -1;
    for (var r = rows - 1; r >= 0; r--) if (board[r * columns + column] < 0) { row = r; break; }
    if (row < 0) return false;
    board[row * columns + column] = value;
    final result = _won(row, column, value);
    board[row * columns + column] = -1;
    return result;
  }

  bool _won(int row, int column, int value) {
    const directions = <List<int>>[<int>[0, 1], <int>[1, 0], <int>[1, 1], <int>[1, -1]];
    for (final d in directions) if (1 + _count(row, column, d[0], d[1], value) + _count(row, column, -d[0], -d[1], value) >= 4) return true;
    return false;
  }

  int _count(int row, int column, int dr, int dc, int value) {
    var count = 0, r = row + dr, c = column + dc;
    while (r >= 0 && r < rows && c >= 0 && c < columns && board[r * columns + c] == value) { count++; r += dr; c += dc; }
    return count;
  }

  String get message => winner != null ? (botMode && winner == 1 ? 'فاز الروبوت' : 'فاز اللاعب ${winner! + 1} 🎉') : draw ? 'انتهت الجولة بالتعادل' : botMode && player == 1 ? 'الروبوت يفكر...' : 'دور اللاعب ${player + 1} — اختر عمودًا';

  @override
  void dispose() { botTimer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) => ConfettiOverlay(
    key: confettiKey,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
      child: Column(children: <Widget>[
        GameHeader(title: 'أربع قطع في صف', subtitle: message, color: const Color(0xFF2563EB), onReset: _reset),
        const SizedBox(height: 10),
        Row(children: <Widget>[
          Expanded(child: ChoiceChip(label: const Text('مع صديق'), selected: !botMode, onSelected: (_) => _setBotMode(false))),
          const SizedBox(width: 8),
          Expanded(child: ChoiceChip(label: const Text('ضد الروبوت'), selected: botMode, onSelected: (_) => _setBotMode(true))),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          _Badge(number: 1, color: colors[0], active: player == 0 && winner == null && !draw),
          const SizedBox(width: 16),
          _Badge(number: 2, color: colors[1], active: player == 1 && winner == null && !draw, robot: botMode),
        ]),
        const SizedBox(height: 12),
        Expanded(child: Center(child: AspectRatio(
          aspectRatio: columns / rows,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF1D4ED8), borderRadius: BorderRadius.circular(24), boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x442563EB), blurRadius: 16, offset: Offset(0, 8))]),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns),
              itemCount: rows * columns,
              itemBuilder: (context, index) {
                final value = board[index];
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _drop(index % columns),
                  child: Padding(padding: const EdgeInsets.all(3), child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: value < 0 ? const Color(0xFFF8FAFC) : colors[value], boxShadow: value < 0 ? null : const <BoxShadow>[BoxShadow(color: Color(0x44000000), blurRadius: 5, offset: Offset(0, 3))]),
                  )),
                );
              },
            ),
          ),
        ))),
        const SizedBox(height: 8),
        const Text('أول لاعب يجمع أربع قطع متصلة يفوز', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
      ]),
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({required this.number, required this.color, required this.active, this.robot = false});
  final int number;
  final Color color;
  final bool active;
  final bool robot;
  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: const Duration(milliseconds: 180),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
    decoration: BoxDecoration(color: color.withAlpha(active ? 55 : 20), borderRadius: BorderRadius.circular(18), border: Border.all(color: color, width: active ? 3 : 1)),
    child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
      Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
      const SizedBox(width: 7),
      Text(robot ? 'الروبوت' : 'اللاعب $number', style: const TextStyle(fontWeight: FontWeight.w900)),
    ]),
  );
}