import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class SeegaPage extends StatefulWidget {
  const SeegaPage({super.key});

  @override
  State<SeegaPage> createState() => _SeegaPageState();
}

class _SeegaPageState extends State<SeegaPage> {
  final List<int> board = List<int>.filled(25, 0);
  int player = 1;
  int redPlaced = 0;
  int bluePlaced = 0;
  int? selected;
  int redWins = 0;
  int blueWins = 0;
  String message = 'ضع الحصى على اللوحة';
  bool busy = false;
  bool finished = false;

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
      busy = false;
      finished = false;
    });
    SoundService.instance.play('click.wav');
  }

  int rowOf(int index) => index ~/ 5;
  int colOf(int index) => index % 5;

  bool inBoard(int row, int col) => row >= 0 && row < 5 && col >= 0 && col < 5;
  int indexOf(int row, int col) => row * 5 + col;

  bool adjacent(int a, int b) {
    final dr = (rowOf(a) - rowOf(b)).abs();
    final dc = (colOf(a) - colOf(b)).abs();
    return dr + dc == 1;
  }

  Future<void> tapCell(int index) async {
    if (busy || finished) return;

    if (placingPhase) {
      if (board[index] != 0 || index == 12) return;
      setState(() {
        busy = true;
        board[index] = player;
        if (player == 1) {
          redPlaced++;
        } else {
          bluePlaced++;
        }
      });
      await SoundService.instance.play('move.wav');
      if (!mounted) return;
      _nextTurn();
      setState(() => busy = false);
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
      setState(() {
        selected = index;
        message = 'اختر خانة قريبة فارغة';
      });
      SoundService.instance.play('tap.wav');
      return;
    }

    final from = selected!;
    if (board[index] != 0 || !adjacent(from, index)) {
      await SoundService.instance.play('wrong.wav');
      if (!mounted) return;
      setState(() => message = 'الحركة يجب أن تكون لخانة قريبة');
      return;
    }

    setState(() {
      busy = true;
      board[index] = player;
      board[from] = 0;
      selected = null;
    });
    await SoundService.instance.play('move.wav');
    if (!mounted) return;

    final captureResult = await _captureAndCheckWinner(index);
    if (!mounted) return;
    if (captureResult >= 0) {
      _nextTurn(captured: captureResult > 0);
    }
    setState(() => busy = false);
  }

  Future<int> _captureAndCheckWinner(int index) async {
    final enemy = player == 1 ? 2 : 1;
    final row = rowOf(index);
    final col = colOf(index);
    final captures = <int>{};
    const directions = <(int, int)>[(0, -1), (0, 1), (-1, 0), (1, 0)];

    for (final direction in directions) {
      final adjacentRow = row + direction.$1;
      final adjacentCol = col + direction.$2;
      final beyondRow = row + direction.$1 * 2;
      final beyondCol = col + direction.$2 * 2;
      if (!inBoard(adjacentRow, adjacentCol) || !inBoard(beyondRow, beyondCol)) continue;

      final adjacentIndex = indexOf(adjacentRow, adjacentCol);
      final beyondIndex = indexOf(beyondRow, beyondCol);
      if (board[adjacentIndex] == enemy && board[beyondIndex] == player) {
        captures.add(adjacentIndex);
      }
    }

    if (captures.isNotEmpty) {
      setState(() {
        for (final captured in captures) {
          board[captured] = 0;
        }
        message = captures.length == 1 ? 'أكلت حصاة!' : 'أكلت ${captures.length} حصوات!';
      });
      await SoundService.instance.play('pop.wav');
      if (!mounted) return -1;
    }

    final red = board.where((value) => value == 1).length;
    final blue = board.where((value) => value == 2).length;
    if (red <= 1 || blue <= 1) {
      final winner = player;
      setState(() {
        finished = true;
        selected = null;
        if (winner == 1) {
          redWins++;
          message = 'فاز الأحمر في السيجا 🎉';
        } else {
          blueWins++;
          message = 'فاز الأزرق في السيجا 🎉';
        }
      });
      await ScoreService.instance.addStars(3);
      await SoundService.instance.play('win.wav');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      }
      return -1;
    }

    return captures.length;
  }

  void _nextTurn({bool captured = false}) {
    setState(() {
      player = player == 1 ? 2 : 1;
      selected = null;
      final nextPlayer = player == 1 ? 'الأحمر' : 'الأزرق';
      if (placingPhase) {
        message = 'ضع الحصى على اللوحة';
      } else if (captured) {
        message = 'تم الأكل، دور $nextPlayer';
      } else {
        message = 'حرّك حصاة وحاول الأكل';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final redCount = board.where((value) => value == 1).length;
    final blueCount = board.where((value) => value == 2).length;
    return Scaffold(
      appBar: AppBar(title: const Text('السيجا'), actions: <Widget>[IconButton(onPressed: reset, icon: const Icon(Icons.refresh_rounded))]),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          children: <Widget>[
            _SeegaHeader(playerName: playerName, playerColor: playerColor, message: message, red: redCount, blue: blueCount, redWins: redWins, blueWins: blueWins, finished: finished),
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
                    itemBuilder: (context, index) => _SeegaCell(owner: board[index], isCenter: index == 12, selected: selected == index, enabled: !busy && !finished, onTap: () => tapCell(index)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (finished)
              SizedBox(width: double.infinity, height: 52, child: FilledButton.icon(onPressed: reset, icon: const Icon(Icons.replay_rounded), label: const Text('جولة جديدة')))
            else
              _SeegaHint(placing: placingPhase),
          ],
        ),
      ),
    );
  }
}

class _SeegaHeader extends StatelessWidget {
  const _SeegaHeader({required this.playerName, required this.playerColor, required this.message, required this.red, required this.blue, required this.redWins, required this.blueWins, required this.finished});
  final String playerName;
  final Color playerColor;
  final String message;
  final int red;
  final int blue;
  final int redWins;
  final int blueWins;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors: <Color>[Color(0xFF1E3A8A), Color(0xFF0F766E)])),
      child: Row(children: <Widget>[
        Icon(finished ? Icons.emoji_events_rounded : Icons.grid_4x4_rounded, color: finished ? const Color(0xFFFFD65C) : playerColor, size: 44),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text(finished ? 'انتهت الجولة' : 'دور $playerName', style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 21, fontWeight: FontWeight.w900)),
          Text(message, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFFE0F2FE), fontWeight: FontWeight.w700)),
          Text('حصى: أحمر $red / أزرق $blue  •  فوز $redWins-$blueWins', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
      ]),
    );
  }
}

class _SeegaCell extends StatelessWidget {
  const _SeegaCell({required this.owner, required this.isCenter, required this.selected, required this.enabled, required this.onTap});
  final int owner;
  final bool isCenter;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = owner == 1 ? const Color(0xFFDC2626) : owner == 2 ? const Color(0xFF2563EB) : const Color(0xFFF8FAFC);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: enabled ? onTap : null,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled ? 1 : 0.78,
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
      ),
    );
  }
}

class _SeegaHint extends StatelessWidget {
  const _SeegaHint({required this.placing});
  final bool placing;
  @override
  Widget build(BuildContext context) {
    return Container(height: 56, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF93C5FD))), child: Row(children: <Widget>[const Icon(Icons.info_rounded, color: Color(0xFF2563EB)), const SizedBox(width: 8), Expanded(child: Text(placing ? 'ضع 6 حصوات لكل لاعب حول اللوحة.' : 'حرّك حصاة قريبة وحاصر حصاة الخصم بين حصاتين.', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w700)))]));
  }
}
