import 'package:flutter/material.dart';
import '../services/score_service.dart';
import '../services/sound_service.dart';

class SmartMazePage extends StatefulWidget {
  const SmartMazePage({super.key});
  @override
  State<SmartMazePage> createState() => _SmartMazePageState();
}

class _SmartMazePageState extends State<SmartMazePage> {
  int pos = 0;
  int moves = 0;
  final int goal = 24;
  final Set<int> walls = <int>{6, 7, 12, 17, 18};
  void reset() { setState(() { pos = 0; moves = 0; }); }
  void move(int dx, int dy) {
    final r = pos ~/ 5;
    final c = pos % 5;
    final nr = r + dy;
    final nc = c + dx;
    if (nr < 0 || nr > 4 || nc < 0 || nc > 4) return;
    final next = nr * 5 + nc;
    if (walls.contains(next)) return;
    setState(() { pos = next; moves++; });
    SoundService.instance.play('move.wav');
    if (pos == goal) { ScoreService.instance.addStars(3); SoundService.instance.play('win.wav'); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('المتاهة الذكية - $moves')), body: ListView(padding: const EdgeInsets.all(18), children: [
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: 25, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, mainAxisSpacing: 6, crossAxisSpacing: 6), itemBuilder: (context, i) {
        final text = i == pos ? '😀' : i == goal ? '⭐' : walls.contains(i) ? '🧱' : '';
        return Container(alignment: Alignment.center, decoration: BoxDecoration(color: walls.contains(i) ? const Color(0xFFCBD5E1) : Colors.white, borderRadius: BorderRadius.circular(12)), child: Text(text, style: const TextStyle(fontSize: 24)));
      }),
      const SizedBox(height: 18),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton.filled(onPressed: () => move(0, -1), icon: const Icon(Icons.keyboard_arrow_up_rounded))]),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton.filled(onPressed: () => move(1, 0), icon: const Icon(Icons.keyboard_arrow_right_rounded)), const SizedBox(width: 20), IconButton.filled(onPressed: () => move(-1, 0), icon: const Icon(Icons.keyboard_arrow_left_rounded))]),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [IconButton.filled(onPressed: () => move(0, 1), icon: const Icon(Icons.keyboard_arrow_down_rounded))]),
      FilledButton.icon(onPressed: reset, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة')),
    ]));
  }
}
