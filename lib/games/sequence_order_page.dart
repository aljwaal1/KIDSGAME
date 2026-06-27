import 'package:flutter/material.dart';
import '../services/score_service.dart';
import '../services/sound_service.dart';

class SequenceOrderPage extends StatefulWidget {
  const SequenceOrderPage({super.key});
  @override
  State<SequenceOrderPage> createState() => _SequenceOrderPageState();
}

class _SequenceOrderPageState extends State<SequenceOrderPage> {
  List<int> items = <int>[3, 1, 4, 2];
  int score = 0;
  bool get solved => items.join(',') == '1,2,3,4';
  void reset() { setState(() { items = <int>[3, 1, 4, 2]..shuffle(); }); }
  void check() { if (solved) { score++; ScoreService.instance.addStars(2); SoundService.instance.play('win.wav'); } else { SoundService.instance.play('wrong.wav'); } setState(() {}); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('رتّب التسلسل - $score'), actions: [IconButton(onPressed: reset, icon: const Icon(Icons.shuffle_rounded))]), body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('رتب الأرقام من الأصغر إلى الأكبر', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 18),
      for (var i = 0; i < items.length; i++) Padding(padding: const EdgeInsets.only(bottom: 10), child: Card(child: ListTile(leading: const Icon(Icons.drag_indicator_rounded), title: Text('${items[i]}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900)), trailing: Row(mainAxisSize: MainAxisSize.min, children: [IconButton(onPressed: i == 0 ? null : () { setState(() { final t = items[i - 1]; items[i - 1] = items[i]; items[i] = t; }); }, icon: const Icon(Icons.keyboard_arrow_up_rounded)), IconButton(onPressed: i == items.length - 1 ? null : () { setState(() { final t = items[i + 1]; items[i + 1] = items[i]; items[i] = t; }); }, icon: const Icon(Icons.keyboard_arrow_down_rounded))]))),
      FilledButton.icon(onPressed: check, icon: const Icon(Icons.check_rounded), label: const Text('تحقق')),
    ]));
  }
}
