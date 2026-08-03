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
  int placedThisTurn = 0;
  int? selected;
  int redWins = 0;
  int blueWins = 0;
  String message = 'ضع الحصى على اللوحة';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showInstructions();
    });
  }

  void _showInstructions() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _SeegaInstructions(),
    );
  }

  bool get placingPhase => redPlaced < 12 || bluePlaced < 12;
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
      placedThisTurn = 0;
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
        placedThisTurn++;
      });
      await SoundService.instance.play('move.wav');
      if (!placingPhase) {
        setState(() {
          placedThisTurn = 0;
          message = 'حرّك حصاة وحاول الأكل';
        });
      } else if (placedThisTurn >= 2 || (player == 1 ? redPlaced >= 12 : bluePlaced >= 12)) {
        nextTurn();
      } else {
        setState(() => message = 'ضع الحصاة الثانية');
      }
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
    final captured = await checkSimpleTrap(index);
    if (captured) {
      setState(() => message = 'أكلت حصاة — العب مرة أخرى');
    } else {
      nextTurn();
    }
  }

  Future<bool> checkSimpleTrap(int index) async {
    final enemy = player == 1 ? 2 : 1;
    final r = rowOf(index);
    final c = colOf(index);
    final captures = <int>[];

    for (final direction in const <List<int>>[<int>[-1, 0], <int>[1, 0], <int>[0, -1], <int>[0, 1]]) {
      final enemyRow = r + direction[0];
      final enemyCol = c + direction[1];
      final ownRow = r + direction[0] * 2;
      final ownCol = c + direction[1] * 2;
      if (enemyRow < 0 || enemyRow >= 5 || enemyCol < 0 || enemyCol >= 5 || ownRow < 0 || ownRow >= 5 || ownCol < 0 || ownCol >= 5) continue;
      final enemyIndex = enemyRow * 5 + enemyCol;
      final ownIndex = ownRow * 5 + ownCol;
      if (enemyIndex != 12 && board[enemyIndex] == enemy && board[ownIndex] == player) captures.add(enemyIndex);
    }

    if (captures.isNotEmpty) {
      setState(() {
        for (final c in captures) {
          board[c] = 0;
        }
      });
      await SoundService.instance.play('pop.wav');
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
    return captures.isNotEmpty;
  }

  void nextTurn() {
    setState(() {
      player = player == 1 ? 2 : 1;
      placedThisTurn = 0;
      selected = null;
      message = placingPhase ? 'ضع الحصى على اللوحة' : 'حرّك حصاة وحاول الأكل';
    });
  }

  @override
  Widget build(BuildContext context) {
    final redCount = board.where((v) => v == 1).length;
    final blueCount = board.where((v) => v == 2).length;
    return Scaffold(
      appBar: AppBar(title: const Text('السيجا'), actions: <Widget>[IconButton(tooltip: 'طريقة اللعب', onPressed: _showInstructions, icon: const Icon(Icons.help_outline_rounded)), IconButton(onPressed: reset, icon: const Icon(Icons.refresh_rounded))]),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          children: <Widget>[
            _SeegaHeader(playerName: playerName, playerColor: playerColor, message: message, red: redCount, blue: blueCount, redWins: redWins, blueWins: blueWins),
            const SizedBox(height: 7),
            _PhaseStrip(placing: placingPhase, redPlaced: redPlaced, bluePlaced: bluePlaced),
            const SizedBox(height: 7),
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
    return Container(height: 56, padding: const EdgeInsets.symmetric(horizontal: 14), decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF93C5FD))), child: Row(children: <Widget>[const Icon(Icons.info_rounded, color: Color(0xFF2563EB)), const SizedBox(width: 8), Expanded(child: Text(placing ? 'ضع حصاتين في دورك حتى يصبح لكل لاعب 12 حصاة.' : 'حرّك حصاة قريبة وحاول حصر حصاة الخصم.', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.w700)))]));
  }
}

class _PhaseStrip extends StatelessWidget {
  const _PhaseStrip({required this.placing, required this.redPlaced, required this.bluePlaced});
  final bool placing;
  final int redPlaced;
  final int bluePlaced;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(color: placing ? const Color(0xFFFFF7ED) : const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(15), border: Border.all(color: placing ? const Color(0xFFF59E0B) : const Color(0xFF10B981))),
      child: Row(children: <Widget>[
        CircleAvatar(radius: 15, backgroundColor: placing ? const Color(0xFFF59E0B) : const Color(0xFF10B981), child: Text(placing ? '1' : '2', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
        const SizedBox(width: 8),
        Expanded(child: Text(placing ? 'مرحلة الوضع: الأحمر $redPlaced/12 • الأزرق $bluePlaced/12' : 'مرحلة اللعب: اختر حصاة ثم حرّكها خانة واحدة', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900))),
      ]),
    );
  }
}

class _SeegaInstructions extends StatelessWidget {
  const _SeegaInstructions();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Text('كيف تلعب السيجا؟', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, fontFamily: 'Changa')),
            const SizedBox(height: 12),
            const _InstructionStep(number: '1', icon: Icons.add_circle_outline_rounded, title: 'ضع الحصى', text: 'يضع كل لاعب حصاتين في دوره حتى يصبح لديه 12 حصاة. خانة النجمة في الوسط تبقى فارغة.'),
            const _InstructionStep(number: '2', icon: Icons.touch_app_rounded, title: 'اختر ثم تحرّك', text: 'بعد اكتمال الوضع، اضغط حصاتك ثم اضغط خانة فارغة ملاصقة لها: أعلى أو أسفل أو يمين أو يسار.'),
            const _InstructionStep(number: '3', icon: Icons.compress_rounded, title: 'احصر حصاة الخصم', text: 'إذا أصبحت حصاة الخصم بين حصاتين لك أفقياً أو عمودياً، تُؤكل وتلعب مرة أخرى. حصاة الوسط آمنة.'),
            const _InstructionStep(number: '4', icon: Icons.emoji_events_rounded, title: 'الفوز', text: 'يفوز اللاعب عندما لا يبقى للخصم إلا حصاة واحدة.'),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, child: FilledButton.icon(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.play_arrow_rounded), label: const Text('فهمت — ابدأ اللعب'))),
          ],
        ),
      ),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  const _InstructionStep({required this.number, required this.icon, required this.title, required this.text});
  final String number;
  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(children: <Widget>[
        CircleAvatar(radius: 19, backgroundColor: const Color(0xFF1E3A8A), child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
        const SizedBox(width: 9),
        Icon(icon, color: const Color(0xFF0F766E), size: 27),
        const SizedBox(width: 9),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          Text(text, style: const TextStyle(color: Color(0xFF475569), fontSize: 12, height: 1.35)),
        ])),
      ]),
    );
  }
}
