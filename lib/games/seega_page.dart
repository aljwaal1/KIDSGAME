import 'dart:math';
import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class SeegaPage extends StatefulWidget {
  const SeegaPage({super.key});

  @override
  State<SeegaPage> createState() => _SeegaPageState();
}

class _SeegaPageState extends State<SeegaPage> {
  final Random random = Random();
  final List<int> board = List<int>.filled(25, 0);
  int player = 1;
  int redPlaced = 0;
  int bluePlaced = 0;
  int? selected;
  int redWins = 0;
  int blueWins = 0;
  String message = 'ضع الحصى على اللوحة';

  bool get placingPhase => redPlaced < 6 || bluePlaced < 6;
  String get playerName => player == 1 ? 'الأحمر' : 'الأزرق';
  Color get playerColor => player == 1 ? const Color(0xFFDC2626) : const Color(0xFF2563EB);

  void reset() {
    setState(() {
      for (var i = 0; i < board.length; i++) {
        board[i] = 0;
      }
      player = 1;
      redPlaced = 0;
      bluePlaced = 0;
      selected = null;
      message = 'ضع الحصى على اللوحة';
    });
    SoundService.instance.play('click.wav');
  }

  int rowOf(int index) => index ~/ 5;
  int colOf(int index) => index % 5;

  bool adjacent(int a, int b) {
    final dr = (rowOf(a) - rowOf(b)).abs();
    final dc = (colOf(a) - colOf(b)).abs();
    return dr + dc == 1;
  }

  Future<void> tapCell(int index) async {
    if (placingPhase) {
      if (board[index] != 0 || index == 12) return;
      setState(() {
        board[index] = player;
        if (player == 1) redPlaced++; else bluePlaced++;
      });
      await SoundService.instance.play('move.wav');
      await checkSimpleTrap(index);
      nextTurn();
      return;
    }

    if (selected == null) {
      if (board[index] != player) return;
      setState(() {
        selected = index;
        message = 'اختر خانة قريبة فارغة';
      });
      SoundService.instance.play('tap.wav');
      return;
    }

    if (board[index] == player) {
      setState(() => selected = index);
      SoundService.instance.play('tap.wav');
      return;
    }

    final from = selected!;
    if (board[index] != 0 || !adjacent(from, index)) {
      await SoundService.instance.play('wrong.wav');
      setState(() => message = 'الحركة يجب أن تكون لخانة قريبة');
      return;
    }

    setState(() {
      board[index] = player;
      board[from] = 0;
      selected = null;
    });
    await SoundService.instance.play('move.wav');
    await checkSimpleTrap(index);
    nextTurn();
  }

  Future<void> checkSimpleTrap(int index) async {
    final enemy = player == 1 ? 2 : 1;
    final r = rowOf(index);
    final c = colOf(index);
    final captures = <int>[];

    final pairs = <List<int>>[
      <int>[index - 1, index + 1],
      <int>[index - 5, index + 5],
    ];

    for (final pair in pairs) {
      if (pair.any((p) => p < 0 || p >= 25)) continue;
      if ((pair[0] ~/ 5 != r && pair[1] ~/ 5 != r) && (pair[0] % 5 != c && pair[1] % 5 != c)) continue;
      if (board[pair[0]] == enemy && board[pair[1]] == player) captures.add(pair[0]);
      if (board[pair[1]] == enemy && board[pair[0]] == player) captures.add(pair[1]);
    }

    if (captures.isNotEmpty) {
      setState(() {
        for (final c in captures) {
          board[c] = 0;
        }
      });
      await SoundService.instance.play('pop.wav');
      message = 'أكلت حصاة!';
    }

    final red = board.where((v) => v == 1).length;
    final blue = board.where((v) => v == 2).length;
    if (!placingPhase && (red <= 1 || blue <= 1)) {
      if (red > blue) redWins++; else blueWins++;
      await ScoreService.instance.addStars(3);
      await SoundService.instance.play('win.wav');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(red > blue ? 'فاز الأحمر في السيجا' : 'فاز الأزرق في السيجا')));
      }
      reset();
    }
  }

  void nextTurn() {
    setState(() {
      player = player == 1 ? 2 : 1;
      selected = null;
      message = placingPhase ? 'ضع الحصى على اللوحة' : 'حرّك حصاة وحاول الأكل';
    });
  }

  @override
  Widget build(BuildContext context) {
    final redCount = board.where((v) => v == 1).length;
    final blueCount = board.where((v) => v == 2).length;
    return Scaffold(
      appBar: AppBar(title: const Text('السيجا'), actions: <Widget>[IconButton(onPressed: reset, icon: const Icon(Icons.refresh_rounded))]),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          children: <Widget>[
            _SeegaHeader(playerName: playerName, playerColor: playerColor, message: message, red: redCount, blue: blueCount, redWins: redWins, blueWins: blueWins),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(8),
                    itemCount: 25,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 8, crossAxisSpacing: 8),
                    itemBuilder: (context, index) => _SeegaCell(owner: board[index], isCenter: index == 12, selected: selected == index, onTap: () => tapCell(index)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _SeegaHint(placing: placingPhase),
          ],
        ),
      ),
    );
  }
}

class _SeegaHeader extends StatelessWidget {
  const _SeegaHeader({required this.playerName, required this.playerColor, required this.message, required this.red, required this.blue, required this.redWins, required this.blueWins});
  final String playerName;
  final Color playerColor;
  final String message;
  final int red;
  final int blue;
  final int redWins;
  final int blueWins;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors: <Color>[Color(0xFF1E3A8A), Color(0xFF0F766E)])),
      child: Row(children: <Widget>[
        Icon(Icons.grid_4x4_rounded, color: playerColor, size: 44),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text('دور $playerName', style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 21, fontWeight: FontWeight.w900)),
          Text(message, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFE0F2FE), fontWeight: FontWeight.w700)),
          Text('حصى: أحمر $red / أزرق $blue  •  فوز $redWins-$blueWins', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
      ]),
    );
  }
}

class _SeegaCell extends StatelessWidget {
  const _SeegaCell({required this.owner, required this.isCenter, required this.selected, required this.onTap});
  final int owner;
  final bool isCenter;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = owner == 1 ? const Color(0xFFDC2626) : owner == 2 ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: isCenter ? const Color(0xFFFFF7ED) : const Color(0xFFE0F2FE),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? const Color(0xFFFFD65C) : const Color(0xFF0369A1), width: selected ? 4 : 2),
        ),
        child: Center(
          child: owner == 0
              ? Icon(isCenter ? Icons.star_border_rounded : Icons.circle_outlined, color: const Color(0xFF64748B), size: 23)
              : Container(width: 36, height: 36, decoration: BoxDecoration(shape: BoxShape.circle, color: color, boxShadow: <BoxShadow>[BoxShadow(color: color.withAlpha(80), blurRadius: 8, offset: const Offset(0, 4))])),
        ),
      ),
    );
  }
}

class _SeegaHint extends StatelessWidget {
  const _SeegaHint({required this.placing});
  final bool placing;
  @override
  Widget build(BuildContext context) {
    return Container(height: 56, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF93C5FD))), child: Row(children: <Widget>[const Icon(Icons.info_rounded, color: Color(0xFF2563EB)), const SizedBox(width: 8), Expanded(child: Text(placing ? 'ضع 6 حصوات لكل لاعب حول اللوحة.' : 'حرّك حصاة قريبة وحاول حصر حصاة الخصم.', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w700)))]));
  }
}
