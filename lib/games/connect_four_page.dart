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
  int selectedColumn = 3;
  bool botMode = false;
  int? winner;
  bool draw = false;

  @override
  void initState() { super.initState(); _reset(); }
  void _reset() {
    botTimer?.cancel();
    board = List<int>.filled(rows * columns, -1);
    setState(() { player = 0; selectedColumn = 3; winner = null; draw = false; });
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
      selectedColumn = column;
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
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(textScaler: const TextScaler.linear(1.0)),
      child: ConfettiOverlay(
        key: confettiKey,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(children: <Widget>[
            GameHeader(title: 'أربع قطع في صف', subtitle: message, color: const Color(0xFF2563EB), onReset: _reset),
            const SizedBox(height: 7),
            Row(children: <Widget>[
              Expanded(child: _ModeButton(label: 'مع صديق', icon: Icons.people_alt_rounded, selected: !botMode, onTap: () => _setBotMode(false))),
              const SizedBox(width: 7),
              Expanded(child: _ModeButton(label: 'ضد الروبوت', icon: Icons.smart_toy_rounded, selected: botMode, onTap: () => _setBotMode(true))),
            ]),
            const SizedBox(height: 7),
            Row(children: <Widget>[
              Expanded(child: _Badge(number: 1, color: colors[0], active: player == 0 && winner == null && !draw)),
              const SizedBox(width: 7),
              Expanded(child: _Badge(number: 2, color: colors[1], active: player == 1 && winner == null && !draw, robot: botMode)),
            ]),
            const SizedBox(height: 7),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maximumBoardWidth = min(
                    constraints.maxWidth,
                    (constraints.maxHeight - 39) * columns / rows,
                  ).toDouble();
                  return Center(
                    child: SizedBox(
                      width: maximumBoardWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(
                            height: 34,
                            child: Row(
                              children: <Widget>[
                                for (var column = 0; column < columns; column++)
                                  Expanded(
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () => _drop(column),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 160),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: selectedColumn == column ? colors[player].withAlpha(45) : Colors.transparent,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.arrow_drop_down_rounded,
                                          color: selectedColumn == column ? colors[player] : const Color(0xFF94A3B8),
                                          size: selectedColumn == column ? 32 : 25,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          AspectRatio(
                            aspectRatio: columns / rows,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: <Color>[Color(0xFF3B82F6), Color(0xFF1D4ED8), Color(0xFF1E40AF)],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(color: const Color(0xFF60A5FA), width: 3),
                                boxShadow: const <BoxShadow>[
                                  BoxShadow(color: Color(0x552563EB), blurRadius: 18, offset: Offset(0, 9)),
                                ],
                              ),
                              child: GridView.builder(
                                padding: EdgeInsets.zero,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns),
                                itemCount: rows * columns,
                                itemBuilder: (context, index) {
                                  final value = board[index];
                                  return GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => _drop(index % columns),
                                    child: Padding(
                                      padding: const EdgeInsets.all(2.5),
                                      child: Container(
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF0F2E78),
                                          boxShadow: <BoxShadow>[
                                            BoxShadow(color: Color(0x99000000), blurRadius: 4, offset: Offset(0, 2)),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(3),
                                        child: value < 0
                                            ? const DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF1F5F9)))
                                            : TweenAnimationBuilder<double>(
                                                key: ValueKey<String>('piece-$index-$value'),
                                                tween: Tween<double>(begin: 0, end: 1),
                                                duration: const Duration(milliseconds: 360),
                                                curve: Curves.bounceOut,
                                                builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                                                child: DecoratedBox(
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    gradient: RadialGradient(
                                                      center: const Alignment(-0.35, -0.35),
                                                      colors: <Color>[Colors.white.withAlpha(150), colors[value], colors[value]],
                                                      stops: const <double>[0, .32, 1],
                                                    ),
                                                    border: Border.all(color: colors[value].withAlpha(230), width: 2),
                                                  ),
                                                ),
                                              ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(14)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                Icon(Icons.touch_app_rounded, color: Color(0xFF2563EB), size: 19),
                SizedBox(width: 6),
                Flexible(child: Text('اضغط أي عمود لإسقاط القطعة • صِل أربع قطع لتفوز', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 12, fontWeight: FontWeight.w900))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.label, required this.icon, required this.selected, required this.onTap});
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(14),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 42,
      decoration: BoxDecoration(color: selected ? const Color(0xFF2563EB) : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: selected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Icon(icon, color: selected ? Colors.white : const Color(0xFF475569), size: 19),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: selected ? Colors.white : const Color(0xFF475569), fontWeight: FontWeight.w900)),
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
    height: 42,
    padding: const EdgeInsets.symmetric(horizontal: 9),
    decoration: BoxDecoration(color: color.withAlpha(active ? 50 : 15), borderRadius: BorderRadius.circular(14), border: Border.all(color: color, width: active ? 2.5 : 1)),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      Container(width: 18, height: 18, decoration: BoxDecoration(shape: BoxShape.circle, color: color, border: Border.all(color: Colors.white, width: 2))),
      const SizedBox(width: 6),
      Flexible(child: Text(robot ? 'الروبوت' : 'اللاعب $number', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900))),
    ]),
  );
}
