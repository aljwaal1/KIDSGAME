import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class SmartMazePage extends StatefulWidget {
  const SmartMazePage({super.key});

  @override
  State<SmartMazePage> createState() => _SmartMazePageState();
}

class _SmartMazePageState extends State<SmartMazePage> {
  final _levels = const [
    _MazeLevel(5, [6, 7, 13, 17], 0, 24),
    _MazeLevel(5, [1, 6, 11, 12, 18], 20, 4),
    _MazeLevel(5, [3, 8, 9, 14, 15, 16], 0, 22),
  ];

  int _levelIndex = 0;
  int _player = 0;
  int _moves = 0;

  _MazeLevel get _level => _levels[_levelIndex];

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  void _startLevel() {
    setState(() {
      _player = _level.start;
      _moves = 0;
    });
  }

  Future<void> _move(int dr, int dc) async {
    final size = _level.size;
    final r = _player ~/ size;
    final c = _player % size;
    final nr = r + dr;
    final nc = c + dc;
    if (nr < 0 || nr >= size || nc < 0 || nc >= size) return;
    final next = nr * size + nc;
    if (_level.blocks.contains(next)) {
      SoundService.instance.play('wrong.wav');
      return;
    }
    SoundService.instance.play('click.wav');
    setState(() {
      _player = next;
      _moves++;
    });
    if (next == _level.goal) {
      SoundService.instance.play('win.wav');
      await ScoreService.instance.addStars(_moves <= 8 ? 5 : 3);
      await ScoreService.instance.reportMoves('smart_maze_${_levelIndex + 1}', _moves);
      if (!mounted) return;
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('وصلت للنجمة!'),
          content: Text('عدد الحركات: $_moves'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إغلاق')),
            FilledButton(onPressed: () { Navigator.pop(context); _nextLevel(); }, child: const Text('المستوى التالي')),
          ],
        ),
      );
    }
  }

  void _nextLevel() {
    setState(() => _levelIndex = (_levelIndex + 1) % _levels.length);
    _startLevel();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('المتاهة الذكية')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFF16A34A), Color(0xFF0EA5E9)])),
              child: Text('حرّك البطل حتى يصل إلى النجمة\nالمستوى ${_levelIndex + 1} • الحركات $_moves', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Changa')),
            ),
            const SizedBox(height: 18),
            AspectRatio(
              aspectRatio: 1,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _level.size * _level.size,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: _level.size, crossAxisSpacing: 8, mainAxisSpacing: 8),
                itemBuilder: (context, index) {
                  final block = _level.blocks.contains(index);
                  final player = index == _player;
                  final goal = index == _level.goal;
                  return Container(
                    decoration: BoxDecoration(
                      color: block ? const Color(0xFF334155) : const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: goal ? const Color(0xFFF59E0B) : Colors.white, width: 2),
                    ),
                    child: Center(
                      child: Icon(
                        player ? Icons.child_care_rounded : goal ? Icons.star_rounded : block ? Icons.close_rounded : Icons.circle_outlined,
                        color: player ? const Color(0xFFEC4899) : goal ? const Color(0xFFF59E0B) : block ? Colors.white : const Color(0xFF7DD3FC),
                        size: player || goal ? 34 : 18,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MoveButton(icon: Icons.keyboard_arrow_right_rounded, onTap: () => _move(0, 1)),
                const SizedBox(width: 10),
                Column(
                  children: [
                    _MoveButton(icon: Icons.keyboard_arrow_up_rounded, onTap: () => _move(-1, 0)),
                    const SizedBox(height: 10),
                    _MoveButton(icon: Icons.keyboard_arrow_down_rounded, onTap: () => _move(1, 0)),
                  ],
                ),
                const SizedBox(width: 10),
                _MoveButton(icon: Icons.keyboard_arrow_left_rounded, onTap: () => _move(0, -1)),
              ],
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(onPressed: _nextLevel, icon: const Icon(Icons.skip_next_rounded), label: const Text('تغيير المستوى')),
          ],
        ),
      ),
    );
  }
}

class _MoveButton extends StatelessWidget {
  const _MoveButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    return FilledButton.tonal(
      onPressed: onTap,
      style: FilledButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(18)),
      child: Icon(icon, size: 34),
    );
  }
}

class _MazeLevel {
  const _MazeLevel(this.size, this.blocks, this.start, this.goal);
  final int size;
  final List<int> blocks;
  final int start;
  final int goal;
}
