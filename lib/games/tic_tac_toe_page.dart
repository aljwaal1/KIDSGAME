import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/game_header.dart';
import '../widgets/win_line_painter.dart';

const List<List<int>> _kWinLines = [
  [0, 1, 2],
  [3, 4, 5],
  [6, 7, 8],
  [0, 3, 6],
  [1, 4, 7],
  [2, 5, 8],
  [0, 4, 8],
  [2, 4, 6],
];

enum TicTacMode { friend, computer }

class TicTacToePage extends StatefulWidget {
  const TicTacToePage({super.key});

  @override
  State<TicTacToePage> createState() => _TicTacToePageState();
}

class _TicTacToePageState extends State<TicTacToePage>
    with SingleTickerProviderStateMixin {
  List<String> board = List.filled(9, '');
  String player = 'X';
  String message = 'دور اللاعب X';
  bool finished = false;
  bool aiThinking = false;
  List<int> winLine = const [];
  TicTacMode mode = TicTacMode.friend;
  int xWins = 0;
  int oWins = 0;
  int draws = 0;
  final Random random = Random();
  final GlobalKey<ConfettiOverlayState> confettiKey =
      GlobalKey<ConfettiOverlayState>();
  late final AnimationController lineController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 350),
  );

  void setMode(TicTacMode value) {
    if (mode == value) return;
    SoundService.instance.play('click.wav');
    setState(() => mode = value);
    reset();
  }

  void play(int index) {
    if (board[index].isNotEmpty || finished || aiThinking) return;
    if (mode == TicTacMode.computer && player == 'O') return;
    _place(index);
  }

  void _place(int index) {
    SoundService.instance.play('tap.wav');
    setState(() {
      board[index] = player;
      _afterMove();
    });
    if (!finished && mode == TicTacMode.computer && player == 'O') {
      _scheduleAiMove();
    }
  }

  void _afterMove() {
    final winner = _getWinnerLine();
    if (winner != null) {
      winLine = winner;
      final symbol = board[winner.first];
      finished = true;
      if (symbol == 'X') {
        xWins++;
        message = 'فاز اللاعب X 🎉';
      } else {
        oWins++;
        message = mode == TicTacMode.computer ? 'فاز الكمبيوتر 🤖' : 'فاز اللاعب O 🎉';
      }
      HapticFeedback.heavyImpact();
      SoundService.instance.play('win.wav');
      lineController.forward(from: 0);
      confettiKey.currentState?.burst();
      ScoreService.instance.addStars(2);
    } else if (!board.contains('')) {
      message = 'تعادل';
      finished = true;
      draws++;
      HapticFeedback.mediumImpact();
    } else {
      player = player == 'X' ? 'O' : 'X';
      message = mode == TicTacMode.computer && player == 'O'
          ? 'دور الكمبيوتر...'
          : 'دور اللاعب $player';
    }
  }

  List<int>? _getWinnerLine() {
    for (final line in _kWinLines) {
      final a = line[0];
      final b = line[1];
      final c = line[2];
      if (board[a].isNotEmpty && board[a] == board[b] && board[b] == board[c]) {
        return line;
      }
    }
    return null;
  }

  int? _findWinningMove(String symbol) {
    for (final line in _kWinLines) {
      final emptyCells = line.where((i) => board[i].isEmpty).toList();
      if (emptyCells.length != 1) continue;
      final filledWithSymbol = line.where((i) => board[i] == symbol).length;
      if (filledWithSymbol == 2) return emptyCells.first;
    }
    return null;
  }

  int? _chooseAiMove() {
    final winningMove = _findWinningMove('O');
    if (winningMove != null) return winningMove;
    final blockingMove = _findWinningMove('X');
    if (blockingMove != null) return blockingMove;
    if (board[4].isEmpty) return 4;
    final corners = [0, 2, 6, 8]..shuffle(random);
    for (final corner in corners) {
      if (board[corner].isEmpty) return corner;
    }
    final edges = [1, 3, 5, 7]..shuffle(random);
    for (final edge in edges) {
      if (board[edge].isEmpty) return edge;
    }
    return null;
  }

  void _scheduleAiMove() {
    setState(() => aiThinking = true);
    Future.delayed(const Duration(milliseconds: 550), () {
      if (!mounted) return;
      if (finished) {
        setState(() => aiThinking = false);
        return;
      }
      final move = _chooseAiMove();
      setState(() => aiThinking = false);
      if (move != null) {
        _place(move);
      }
    });
  }

  void reset() {
    setState(() {
      board = List.filled(9, '');
      player = 'X';
      message = mode == TicTacMode.computer ? 'دورك الآن، ابدأ اللعب' : 'دور اللاعب X';
      finished = false;
      aiThinking = false;
      winLine = const [];
    });
  }

  @override
  void dispose() {
    lineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiOverlay(
      key: confettiKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          GameHeader(
            title: 'إكس أو',
            subtitle: message,
            color: const Color(0xFF6D28D9),
            onReset: reset,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Text('ضد صديق'),
                  selected: mode == TicTacMode.friend,
                  onSelected: (_) => setMode(TicTacMode.friend),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChoiceChip(
                  label: const Text('ضد الكمبيوتر'),
                  selected: mode == TicTacMode.computer,
                  onSelected: (_) => setMode(TicTacMode.computer),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ScorePill(label: 'X', value: xWins, color: const Color(0xFF6D28D9)),
              _ScorePill(
                label: mode == TicTacMode.computer ? '🤖' : 'O',
                value: oWins,
                color: const Color(0xFFF97316),
              ),
              _ScorePill(label: 'تعادل', value: draws, color: const Color(0xFF64748B)),
            ],
          ),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxWidth;
                return Stack(
                  children: [
                    GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 9,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemBuilder: (context, index) {
                        final value = board[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () => play(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              color: value == 'X'
                                  ? const Color(0xFFEDE9FE)
                                  : value == 'O'
                                      ? const Color(0xFFFFEDD5)
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: winLine.contains(index)
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFE9D5FF),
                                width: winLine.contains(index) ? 4 : 2,
                              ),
                            ),
                            child: Center(
                              child: AnimatedScale(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.elasticOut,
                                scale: value.isEmpty ? 0.0 : 1.0,
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: 54,
                                    fontWeight: FontWeight.w900,
                                    color: value == 'X'
                                        ? const Color(0xFF6D28D9)
                                        : const Color(0xFFF97316),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (winLine.isNotEmpty)
                      IgnorePointer(
                        child: AnimatedBuilder(
                          animation: lineController,
                          builder: (context, _) {
                            return CustomPaint(
                              size: Size.square(size),
                              painter: WinLinePainter(
                                winLine,
                                progress: lineController.value,
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(
            '$value',
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
