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

  void reset() {
    final next = <int>[1, 2, 3, 4]..shuffle();
    setState(() {
      items = next;
    });
  }

  void moveUp(int index) {
    if (index <= 0) return;
    SoundService.instance.play('click.wav');
    setState(() {
      final temp = items[index - 1];
      items[index - 1] = items[index];
      items[index] = temp;
    });
  }

  void moveDown(int index) {
    if (index >= items.length - 1) return;
    SoundService.instance.play('click.wav');
    setState(() {
      final temp = items[index + 1];
      items[index + 1] = items[index];
      items[index] = temp;
    });
  }

  Future<void> checkAnswer() async {
    if (solved) {
      setState(() {
        score++;
      });
      await ScoreService.instance.addStars(2);
      await SoundService.instance.play('win.wav');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ممتاز! الترتيب صحيح')),
      );
    } else {
      await SoundService.instance.play('wrong.wav');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حاول مرة أخرى')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('رتّب التسلسل - $score'),
        actions: <Widget>[
          IconButton(
            onPressed: reset,
            icon: const Icon(Icons.shuffle_rounded),
            tooltip: 'خلط',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: <Widget>[
          const Text(
            'رتب الأرقام من الأصغر إلى الأكبر',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 18),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  leading: const Icon(Icons.drag_indicator_rounded),
                  title: Text(
                    '${items[i]}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        onPressed: i == 0 ? null : () => moveUp(i),
                        icon: const Icon(Icons.keyboard_arrow_up_rounded),
                      ),
                      IconButton(
                        onPressed: i == items.length - 1 ? null : () => moveDown(i),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: checkAnswer,
            icon: const Icon(Icons.check_rounded),
            label: const Text('تحقق'),
          ),
        ],
      ),
    );
  }
}
