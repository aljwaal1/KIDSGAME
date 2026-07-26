import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/score_service.dart';
import '../services/sound_service.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/game_header.dart';
import '../widgets/win_line_painter.dart';

const List<List<int>> _winLines = <List<int>>[
  <int>[0, 1, 2], <int>[3, 4, 5], <int>[6, 7, 8],
  <int>[0, 3, 6], <int>[1, 4, 7], <int>[2, 5, 8],
  <int>[0, 4, 8], <int>[2, 4, 6],
];

enum TicTacMode { friend, computer }
enum _AiStrength { strong, medium, weak }

class TicTacToePage extends StatefulWidget {
  const TicTacToePage({super.key});
  @override
  State<TicTacToePage> createState() => _TicTacToePageState();
}

class _TicTacToePageState extends State<TicTacToePage> with SingleTickerProviderStateMixin {
  List<String> board = List<String>.filled(9, '');
  String player = 'X';
  String message = 'دور اللاعب X';
  bool finished = false;
  bool aiThinking = false;
  List<int> winLine = <int>[];
  TicTacMode mode = TicTacMode.friend;
  int xWins = 0;
  int oWins = 0;
  int draws = 0;
  int aiRound = 0;
  int roundId = 0;
  _AiStrength aiStrength = _AiStrength.medium;
  final Random random = Random();
  Timer? _aiTimer;
  final GlobalKey<ConfettiOverlayState> confettiKey = GlobalKey<ConfettiOverlayState>();
  late final AnimationController lineController = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));

  void setMode(TicTacMode value) {
    if (mode == value) return;
    SoundService.instance.play('click.wav');
    _cancelAiMove();
    setState(() => mode = value);
    reset();
  }

  void play(int index) {
    if (board[index].isNotEmpty || finished || aiThinking) return;
    if (mode == TicTacMode.computer && player == 'O') return;
    _place(index);
  }

  void _place(int index) {
    if (index < 0 || index >= board.length || board[index].isNotEmpty || finished) return;
    SoundService.instance.play('tap.wav');
    setState(() {
      board[index] = player;
      _afterMove();
    });
    if (!finished && mode == TicTacMode.computer && player == 'O') _scheduleAiMove();
  }

  void _afterMove() {
    final winner = _getWinnerLine();
    if (winner != null) {
      winLine = winner;
      final symbol = board[winner.first];
      finished = true;
      aiThinking = false;
      _aiTimer?.cancel();
      if (symbol == 'X') { xWins++; message = 'فاز اللاعب X 🎉'; }
      else { oWins++; message = mode == TicTacMode.computer ? 'فاز الكمبيوتر 🤖' : 'فاز اللاعب O 🎉'; }
      HapticFeedback.heavyImpact();
      SoundService.instance.play('win.wav');
      lineController.forward(from: 0);
      confettiKey.currentState?.burst();
      ScoreService.instance.addStars(2);
    } else if (!board.contains('')) {
      message = 'تعادل';
      finished = true;
      aiThinking = false;
      _aiTimer?.cancel();
      draws++;
      HapticFeedback.mediumImpact();
    } else {
      player = player == 'X' ? 'O' : 'X';
      message = mode == TicTacMode.computer && player == 'O'
          ? 'دور الكمبيوتر... ${_aiStrengthText()}'
          : 'دور اللاعب $player';
    }
  }

  List<int>? _getWinnerLine() {
    for (final line in _winLines) {
      if (board[line[0]].isNotEmpty && board[line[0]] == board[line[1]] && board[line[1]] == board[line[2]]) return line;
    }
    return null;
  }

  int? _findWinningMove(String symbol) {
    for (final line in _winLines) {
      final empty = line.where((i) => board[i].isEmpty).toList();
      if (empty.length == 1 && line.where((i) => board[i] == symbol).length == 2) return empty.first;
    }
    return null;
  }

  List<int> _emptyCells() => <int>[for (int i = 0; i < board.length; i++) if (board[i].isEmpty) i];

  String _aiStrengthText() {
    switch (aiStrength) {
      case _AiStrength.strong: return '🤖 قوي';
      case _AiStrength.medium: return '🤖 متوسط';
      case _AiStrength.weak: return '🤖 سهل';
    }
  }

  void _prepareNextAiStrength() {
    final List<_AiStrength> cycle = <_AiStrength>[_AiStrength.strong, _AiStrength.weak, _AiStrength.medium, _AiStrength.weak];
    aiStrength = cycle[aiRound % cycle.length];
    aiRound++;
  }

  int? _chooseStrongAiMove() {
    final win = _findWinningMove('O');
    if (win != null) return win;
    final block = _findWinningMove('X');
    if (block != null) return block;
    if (board[4].isEmpty) return 4;
    final corners = <int>[0, 2, 6, 8]..shuffle(random);
    for (final c in corners) { if (board[c].isEmpty) return c; }
    final edges = <int>[1, 3, 5, 7]..shuffle(random);
    for (final e in edges) { if (board[e].isEmpty) return e; }
    return null;
  }

  int? _chooseMediumAiMove() {
    final win = _findWinningMove('O');
    if (win != null) return win;
    if (random.nextBool()) {
      final block = _findWinningMove('X');
      if (block != null) return block;
    }
    if (board[4].isEmpty && random.nextBool()) return 4;
    final cells = _emptyCells()..shuffle(random);
    return cells.isEmpty ? null : cells.first;
  }

  int? _chooseWeakAiMove() {
    final cells = _emptyCells()..shuffle(random);
    if (cells.isEmpty) return null;
    final winningMove = _findWinningMove('O');
    final safeMistakes = cells.where((i) => winningMove != i).toList();
    if (safeMistakes.isNotEmpty && random.nextInt(100) < 70) return safeMistakes.first;
    return cells.first;
  }

  int? _chooseAiMove() {
    switch (aiStrength) {
      case _AiStrength.strong: return _chooseStrongAiMove();
      case _AiStrength.medium: return _chooseMediumAiMove();
      case _AiStrength.weak: return _chooseWeakAiMove();
    }
  }

  void _cancelAiMove() {
    _aiTimer?.cancel();
    _aiTimer = null;
    aiThinking = false;
  }

  void _scheduleAiMove() {
    _aiTimer?.cancel();
    final scheduledRound = roundId;
    setState(() => aiThinking = true);
    _aiTimer = Timer(const Duration(milliseconds: 550), () {
      if (!mounted || scheduledRound != roundId || finished || mode != TicTacMode.computer || player != 'O') return;
      final move = _chooseAiMove();
      setState(() => aiThinking = false);
      if (move != null && board[move].isEmpty) _place(move);
    });
  }

  void reset() {
    _cancelAiMove();
    roundId++;
    setState(() {
      board = List<String>.filled(9, '');
      player = 'X';
      if (mode == TicTacMode.computer) _prepareNextAiStrength();
      message = mode == TicTacMode.computer ? 'دورك الآن، ابدأ اللعب ${_aiStrengthText()}' : 'دور اللاعب X';
      finished = false;
      winLine = <int>[];
    });
  }

  @override
  void dispose() {
    _aiTimer?.cancel();
    lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiOverlay(
      key: confettiKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        child: Column(
          children: <Widget>[
            GameHeader(title: 'إكس أو', subtitle: message, color: const Color(0xFF6D28D9), onReset: reset),
            const SizedBox(height: 8),
            Row(children: <Widget>[
              Expanded(child: ChoiceChip(label: const Text('ضد صديق'), selected: mode == TicTacMode.friend, onSelected: (_) => setMode(TicTacMode.friend))),
              const SizedBox(width: 8),
              Expanded(child: ChoiceChip(label: const Text('ضد الكمبيوتر'), selected: mode == TicTacMode.computer, onSelected: (_) => setMode(TicTacMode.computer))),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
              _ScorePill(label: 'X', value: xWins, color: const Color(0xFF6D28D9)),
              _ScorePill(label: mode == TicTacMode.computer ? '🤖' : 'O', value: oWins, color: const Color(0xFFF97316)),
              _ScorePill(label: 'تعادل', value: draws, color: const Color(0xFF64748B)),
            ]),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(builder: (context, constraints) {
                    final size = constraints.maxWidth;
                    return Stack(children: <Widget>[
                      GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 9,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
                        itemBuilder: (context, index) {
                          final value = board[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(24),
                            onTap: () => play(index),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              decoration: BoxDecoration(
                                color: value == 'X' ? const Color(0xFFEDE9FE) : value == 'O' ? const Color(0xFFFFEDD5) : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: winLine.contains(index) ? const Color(0xFF10B981) : const Color(0xFFE9D5FF), width: winLine.contains(index) ? 4 : 2),
                              ),
                              child: Center(
                                child: AnimatedScale(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.elasticOut,
                                  scale: value.isEmpty ? 0.0 : 1.0,
                                  child: Text(value, style: TextStyle(fontSize: 54, fontWeight: FontWeight.w900, color: value == 'X' ? const Color(0xFF6D28D9) : const Color(0xFFF97316))),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      if (winLine.isNotEmpty)
                        IgnorePointer(child: AnimatedBuilder(animation: lineController, builder: (context, _) => CustomPaint(size: Size.square(size), painter: WinLinePainter(winLine, progress: lineController.value)))),
                    ]);
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  const _ScorePill({required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(14)),
      child: Column(children: <Widget>[
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text('$value', style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 15)),
      ]),
    );
  }
}
