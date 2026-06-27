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
  int tries = 0;

  bool get solved => items.join(',') == '1,2,3,4';

  void _reset() {
    setState(() {
      items = <int>[3, 1, 4, 2]..shuffle();
      tries = 0;
    });
    SoundService.instance.play('click.wav');
  }

  void _swap(int from, int to) {
    if (to < 0 || to >= items.length) return;
    setState(() {
      final temp = items[from];
      items[from] = items[to];
      items[to] = temp;
    });
    SoundService.instance.play('move.wav');
  }

  Future<void> _check() async {
    setState(() => tries++);
    if (solved) {
      await ScoreService.instance.addStars(2);
      await SoundService.instance.play('win.wav');
      if (!mounted) return;
      setState(() => score++);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أحسنت! رتبت التسلسل بشكل صحيح')),
      );
    } else {
      await SoundService.instance.play('wrong.wav');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حاول مرة أخرى، أنت قريب')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رتّب التسلسل'),
        actions: <Widget>[
          IconButton(
            onPressed: _reset,
            tooltip: 'خلط جديد',
            icon: const Icon(Icons.shuffle_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
        children: <Widget>[
          _Header(score: score, tries: tries),
          const SizedBox(height: 16),
          const Text(
            'حرّك الأرقام للأعلى أو للأسفل حتى تصبح مرتبة من 1 إلى 4.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
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
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        onPressed: i == 0 ? null : () => _swap(i, i - 1),
                        icon: const Icon(Icons.keyboard_arrow_up_rounded),
                      ),
                      IconButton(
                        onPressed: i == items.length - 1 ? null : () => _swap(i, i + 1),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _check,
            icon: const Icon(Icons.check_rounded),
            label: const Text('تحقق من الترتيب'),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.score, required this.tries});

  final int score;
  final int tries;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.format_list_numbered_rtl_rounded, color: Color(0xFF4F46E5), size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'رتّب التسلسل',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Changa',
                    color: Color(0xFF312E81),
                  ),
                ),
                const SizedBox(height: 4),
                Text('النقاط: $score  •  المحاولات: $tries'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
