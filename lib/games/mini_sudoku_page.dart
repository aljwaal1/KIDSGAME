import 'package:flutter/material.dart';

import 'package:kids_games_arena/services/score_service.dart';
import 'package:kids_games_arena/services/sound_service.dart';

class MiniSudokuPage extends StatefulWidget {
  const MiniSudokuPage({super.key});

  @override
  State<MiniSudokuPage> createState() => _MiniSudokuPageState();
}

class _MiniSudokuPageState extends State<MiniSudokuPage> {
  static const _solution = [
    [1, 2, 3, 4],
    [3, 4, 1, 2],
    [2, 1, 4, 3],
    [4, 3, 2, 1],
  ];
  static const _fixed = [
    [1, 0, 0, 4],
    [0, 4, 1, 0],
    [0, 1, 4, 0],
    [4, 0, 0, 1],
  ];

  late List<List<int>> _board;
  int _mistakes = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    setState(() {
      _board = List.generate(4, (r) => List.generate(4, (c) => _fixed[r][c]));
      _mistakes = 0;
    });
  }

  Future<void> _tap(int r, int c) async {
    if (_fixed[r][c] != 0) return;
    SoundService.instance.play('click.wav');
    setState(() => _board[r][c] = (_board[r][c] % 4) + 1);
    if (_isFull()) {
      if (_isSolved()) {
        SoundService.instance.play('win.wav');
        await ScoreService.instance.addStars(_mistakes == 0 ? 6 : 4);
        await ScoreService.instance.reportMoves('mini_sudoku', _mistakes + 1);
        if (!mounted) return;
        showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('عبقري!'),
            content: const Text('أكملت سودوكو الأطفال بشكل صحيح.'),
            actions: [FilledButton(onPressed: () { Navigator.pop(context); _reset(); }, child: const Text('لغز جديد'))],
          ),
        );
      } else {
        SoundService.instance.play('wrong.wav');
        setState(() => _mistakes++);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('هناك رقم غير صحيح، راجع الصفوف والمربعات')));
      }
    }
  }

  bool _isFull() => _board.every((row) => row.every((v) => v != 0));
  bool _isSolved() {
    for (var r = 0; r < 4; r++) {
      for (var c = 0; c < 4; c++) {
        if (_board[r][c] != _solution[r][c]) return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('سودوكو الأطفال')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFFACC15)])),
              child: const Text('املأ كل صف وعمود بالأرقام 1 إلى 4 بدون تكرار', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Changa')),
            ),
            const SizedBox(height: 20),
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(22)),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 16,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 6, mainAxisSpacing: 6),
                  itemBuilder: (context, index) {
                    final r = index ~/ 4;
                    final c = index % 4;
                    final value = _board[r][c];
                    final fixed = _fixed[r][c] != 0;
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _tap(r, c),
                      child: Container(
                        decoration: BoxDecoration(
                          color: fixed ? const Color(0xFFDBEAFE) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: (r ~/ 2 + c ~/ 2).isEven ? const Color(0xFF38BDF8) : const Color(0xFFFBBF24), width: 2),
                        ),
                        child: Center(
                          child: Text(value == 0 ? '' : '$value', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: fixed ? const Color(0xFF1D4ED8) : const Color(0xFF0F172A))),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('الأخطاء: $_mistakes', style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _reset, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة اللغز')),
          ],
        ),
      ),
    );
  }
}
