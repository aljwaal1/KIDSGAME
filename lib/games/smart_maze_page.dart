import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class SmartMazePage extends StatefulWidget {
  const SmartMazePage({super.key});
  @override
  State<SmartMazePage> createState() => _SmartMazePageState();
}

class _SmartMazePageState extends State<SmartMazePage> {
  static const int size = 5;
  final Set<int> walls = <int>{6, 8, 11, 13, 16, 18};
  int hero = 0;
  final int goal = 24;
  int moves = 0;
  bool completed = false;
  bool busy = false;

  Future<void> _move(int dr, int dc) async {
    if (completed || busy) return;
    final int row = hero ~/ size;
    final int col = hero % size;
    final int nr = row + dr;
    final int nc = col + dc;
    if (nr < 0 || nr >= size || nc < 0 || nc >= size) return;
    final int next = nr * size + nc;
    if (walls.contains(next)) {
      await SoundService.instance.play('wrong.wav');
      return;
    }
    busy = true;
    setState(() {
      hero = next;
      moves++;
    });
    await SoundService.instance.play('move.wav');
    if (hero == goal) {
      completed = true;
      await ScoreService.instance.addStars(moves <= 10 ? 5 : 3);
      await SoundService.instance.play('win.wav');
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('وصلت للنجمة خلال $moves خطوة')));
    }
    busy = false;
  }

  void _reset() {
    setState(() {
      hero = 0;
      moves = 0;
      completed = false;
      busy = false;
    });
    SoundService.instance.play('click.wav');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('المتاهة الذكية'), actions: <Widget>[IconButton(onPressed: _reset, icon: const Icon(Icons.refresh_rounded))]), body: ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 100), children: <Widget>[
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors: <Color>[Color(0xFF22C55E), Color(0xFF14B8A6)])), child: Text(completed ? 'وصلت إلى النجمة 🎉\nالخطوات: $moves' : 'أوصل البطل إلى النجمة\nالخطوات: $moves', style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 22, fontWeight: FontWeight.w900))),
      const SizedBox(height: 18),
      AspectRatio(aspectRatio: 1, child: GridView.builder(physics: const NeverScrollableScrollPhysics(), itemCount: size * size, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: size, mainAxisSpacing: 6, crossAxisSpacing: 6), itemBuilder: (BuildContext context, int index) {
        final bool wall = walls.contains(index);
        final bool isHero = hero == index;
        final bool isGoal = goal == index;
        return Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), color: wall ? const Color(0xFF334155) : isHero ? const Color(0xFFE0F2FE) : isGoal ? const Color(0xFFFEF3C7) : Colors.white, border: Border.all(color: const Color(0xFFE2E8F0))), child: Icon(isHero ? Icons.child_care_rounded : isGoal ? Icons.star_rounded : wall ? Icons.block_rounded : Icons.circle_outlined, color: isHero ? const Color(0xFF0EA5E9) : isGoal ? const Color(0xFFF59E0B) : wall ? Colors.white : const Color(0xFFCBD5E1)));
      })),
      const SizedBox(height: 18),
      Column(children: <Widget>[
        IconButton.filledTonal(onPressed: completed || busy ? null : () => _move(-1, 0), icon: const Icon(Icons.keyboard_arrow_up_rounded)),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          IconButton.filledTonal(onPressed: completed || busy ? null : () => _move(0, -1), icon: const Icon(Icons.keyboard_arrow_right_rounded)),
          const SizedBox(width: 20),
          IconButton.filledTonal(onPressed: completed || busy ? null : () => _move(0, 1), icon: const Icon(Icons.keyboard_arrow_left_rounded)),
        ]),
        IconButton.filledTonal(onPressed: completed || busy ? null : () => _move(1, 0), icon: const Icon(Icons.keyboard_arrow_down_rounded)),
      ]),
    ]));
  }
}
