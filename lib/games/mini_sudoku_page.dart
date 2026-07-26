import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class MiniSudokuPage extends StatefulWidget {
  const MiniSudokuPage({super.key});
  @override
  State<MiniSudokuPage> createState() => _MiniSudokuPageState();
}

class _MiniSudokuPageState extends State<MiniSudokuPage> {
  final List<int> solution = <int>[1, 2, 3, 4, 3, 4, 1, 2, 2, 1, 4, 3, 4, 3, 2, 1];
  late List<int> values;
  final Set<int> fixed = <int>{0, 3, 5, 6, 9, 10, 12, 15};
  int selected = -1;
  int mistakes = 0;
  bool completed = false;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _prepareBoard();
  }

  void _prepareBoard() {
    values = List<int>.filled(16, 0);
    for (final int i in fixed) {
      values[i] = solution[i];
    }
  }

  Future<void> _put(int number) async {
    if (busy || completed || selected < 0 || fixed.contains(selected)) return;
    busy = true;
    if (solution[selected] == number) {
      setState(() => values[selected] = number);
      await SoundService.instance.play('pop.wav');
      if (!values.contains(0)) {
        completed = true;
        await ScoreService.instance.addStars(5);
        await SoundService.instance.play('win.wav');
        if (!mounted) return;
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ممتاز! أكملت السودوكو')));
      }
    } else {
      setState(() => mistakes++);
      await SoundService.instance.play('wrong.wav');
    }
    busy = false;
  }

  void _reset() {
    setState(() {
      _prepareBoard();
      selected = -1;
      mistakes = 0;
      completed = false;
      busy = false;
    });
    SoundService.instance.play('click.wav');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('سودوكو الأطفال'), actions: <Widget>[IconButton(onPressed: _reset, icon: const Icon(Icons.refresh_rounded))]), body: ListView(padding: const EdgeInsets.fromLTRB(18, 12, 18, 100), children: <Widget>[
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors: <Color>[Color(0xFFF97316), Color(0xFFFACC15)])), child: Text(completed ? 'ممتاز! اكتملت اللوحة 🎉\nالأخطاء: $mistakes' : 'املأ الأرقام من 1 إلى 4\nالأخطاء: $mistakes', style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 22, fontWeight: FontWeight.w900))),
      const SizedBox(height: 18),
      AspectRatio(aspectRatio: 1, child: GridView.builder(physics: const NeverScrollableScrollPhysics(), itemCount: 16, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 6, crossAxisSpacing: 6), itemBuilder: (BuildContext context, int index) {
        final bool isFixed = fixed.contains(index);
        final bool isSelected = selected == index;
        return InkWell(onTap: isFixed || completed ? null : () => setState(() => selected = index), borderRadius: BorderRadius.circular(16), child: Container(decoration: BoxDecoration(color: isFixed ? const Color(0xFFFFEDD5) : isSelected ? const Color(0xFFE0F2FE) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? const Color(0xFF0EA5E9) : const Color(0xFFE2E8F0), width: isSelected ? 3 : 1)), alignment: Alignment.center, child: Text(values[index] == 0 ? '' : '${values[index]}', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: isFixed ? const Color(0xFFF97316) : const Color(0xFF334155)))));
      })),
      const SizedBox(height: 18),
      Row(children: <Widget>[for (int n = 1; n <= 4; n++) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: FilledButton.tonal(onPressed: completed || busy ? null : () => _put(n), child: Text('$n', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)))))]),
    ]));
  }
}
