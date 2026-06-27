import 'package:flutter/material.dart';
import '../services/score_service.dart';
import '../services/sound_service.dart';

class MiniSudokuPage extends StatefulWidget {
  const MiniSudokuPage({super.key});
  @override
  State<MiniSudokuPage> createState() => _MiniSudokuPageState();
}

class _MiniSudokuPageState extends State<MiniSudokuPage> {
  final List<int?> cells = <int?>[1, null, 3, 4, 3, 4, null, 2, null, 1, 4, 3, 4, 3, 2, null];
  final List<int> solution = <int>[1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1];
  int selected = -1;

  void setNumber(int n) {
    if (selected < 0) return;
    setState(() { cells[selected] = n; });
    SoundService.instance.play('click.wav');
    if (_done()) { ScoreService.instance.addStars(3); SoundService.instance.play('win.wav'); }
  }

  bool _done() { for (var i = 0; i < cells.length; i++) { if (cells[i] != solution[i]) return false; } return true; }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سودوكو الأطفال')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 16,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8),
          itemBuilder: (context, i) => InkWell(
            onTap: () => setState(() => selected = i),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(color: selected == i ? const Color(0xFFEDE9FE) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFCBD5E1))),
              child: Text(cells[i]?.toString() ?? '', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(children: [for (var n = 1; n <= 4; n++) Expanded(child: Padding(padding: const EdgeInsets.all(4), child: FilledButton(onPressed: () => setNumber(n), child: Text('$n'))))]),
      ]),
    );
  }
}
