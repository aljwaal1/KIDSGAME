import 'dart:math';
import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class SlidingPuzzlePage extends StatefulWidget {
  const SlidingPuzzlePage({super.key});

  @override
  State<SlidingPuzzlePage> createState() => _SlidingPuzzlePageState();
}

class _SlidingPuzzlePageState extends State<SlidingPuzzlePage> {
  List<int> tiles = [1, 2, 3, 4, 5, 6, 7, 8, 0];
  int moves = 0;

  @override
  void initState() {
    super.initState();
    _shuffle();
  }

  void _shuffle() {
    final rnd = Random();
    setState(() {
      do {
        tiles = [1, 2, 3, 4, 5, 6, 7, 8, 0]..shuffle(rnd);
      } while (!_solvable(tiles) || _solved());
      moves = 0;
    });
  }

  bool _solvable(List<int> list) {
    final a = list.where((x) => x != 0).toList();
    var inv = 0;
    for (var i = 0; i < a.length; i++) {
      for (var j = i + 1; j < a.length; j++) {
        if (a[i] > a[j]) inv++;
      }
    }
    return inv.isEven;
  }

  bool _solved() => tiles.join(',') == '1,2,3,4,5,6,7,8,0';

  void _tap(int index) async {
    final empty = tiles.indexOf(0);
    final r1 = index ~/ 3, c1 = index % 3;
    final r2 = empty ~/ 3, c2 = empty % 3;
    if ((r1 - r2).abs() + (c1 - c2).abs() != 1) return;
    await SoundService.instance.play('click.wav');
    setState(() {
      tiles[empty] = tiles[index];
      tiles[index] = 0;
      moves++;
    });
    if (_solved()) {
      await ScoreService.instance.addStars(4);
      await ScoreService.instance.reportMoves('sliding_3x3', moves);
      await SoundService.instance.play('win.wav');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('أحسنت! أنهيتها خلال $moves حركة')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _PuzzleHeader(title: 'بزل الأرقام', text: 'الحركات: $moves', color: const Color(0xFFF97316)),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 9,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10),
          itemBuilder: (context, i) {
            final n = tiles[i];
            return InkWell(
              onTap: () => _tap(i),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color: n == 0 ? const Color(0xFFFFEDD5) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                alignment: Alignment.center,
                child: Text(n == 0 ? '' : '$n', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFFF97316))),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: _shuffle, icon: const Icon(Icons.shuffle_rounded), label: const Text('خلط جديد')),
      ],
    );
  }
}

class _PuzzleHeader extends StatelessWidget {
  const _PuzzleHeader({required this.title, required this.text, required this.color});
  final String title, text;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        const Icon(Icons.extension_rounded, color: Colors.white, size: 36),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Changa')),
          Text(text, style: const TextStyle(color: Color(0xFFFFF7D6))),
        ])),
      ]),
    );
  }
}
