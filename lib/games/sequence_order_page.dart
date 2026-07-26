import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class SequenceOrderPage extends StatefulWidget {
  const SequenceOrderPage({super.key});

  @override
  State<SequenceOrderPage> createState() => _SequenceOrderPageState();
}

class _SequenceOrderPageState extends State<SequenceOrderPage> {
  List<_StepItem> items = <_StepItem>[
    const _StepItem(3, 'نخرجها من الفرن', Icons.local_fire_department_rounded, Color(0xFFEF4444)),
    const _StepItem(1, 'نجهّز العجينة', Icons.bakery_dining_rounded, Color(0xFFF59E0B)),
    const _StepItem(4, 'نأكلها مع العائلة', Icons.emoji_food_beverage_rounded, Color(0xFF22C55E)),
    const _StepItem(2, 'نضعها في الفرن', Icons.countertops_rounded, Color(0xFF3B82F6)),
  ];
  int score = 0;
  int tries = 0;
  bool completed = false;
  bool checking = false;

  bool get solved {
    for (int i = 0; i < items.length; i++) {
      if (items[i].order != i + 1) return false;
    }
    return true;
  }

  void _reset() {
    setState(() {
      items = <_StepItem>[
        const _StepItem(3, 'نخرجها من الفرن', Icons.local_fire_department_rounded, Color(0xFFEF4444)),
        const _StepItem(1, 'نجهّز العجينة', Icons.bakery_dining_rounded, Color(0xFFF59E0B)),
        const _StepItem(4, 'نأكلها مع العائلة', Icons.emoji_food_beverage_rounded, Color(0xFF22C55E)),
        const _StepItem(2, 'نضعها في الفرن', Icons.countertops_rounded, Color(0xFF3B82F6)),
      ]..shuffle();
      tries = 0;
      completed = false;
      checking = false;
    });
    SoundService.instance.play('click.wav');
  }

  void _swap(int from, int to) {
    if (completed || checking || to < 0 || to >= items.length) return;
    setState(() {
      final _StepItem temp = items[from];
      items[from] = items[to];
      items[to] = temp;
    });
    SoundService.instance.play('move.wav');
  }

  Future<void> _check() async {
    if (checking || completed) return;
    checking = true;
    setState(() => tries++);
    if (solved) {
      completed = true;
      await ScoreService.instance.addStars(3);
      await SoundService.instance.play('win.wav');
      if (!mounted) return;
      setState(() => score++);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رائع! رتبت القصة بشكل صحيح')));
    } else {
      await SoundService.instance.play('wrong.wav');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حاول ترتيب الأحداث من البداية للنهاية')));
    }
    checking = false;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رتّب التسلسل'),
        actions: <Widget>[IconButton(onPressed: _reset, tooltip: 'خلط جديد', icon: const Icon(Icons.shuffle_rounded))],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          children: <Widget>[
            _Header(score: score, tries: tries),
            const SizedBox(height: 8),
            Text(completed ? 'أحسنت! اضغط خلط جديد لجولة أخرى' : 'رتّب القصة بالأسهم من البداية للنهاية', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 14)),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < items.length; i++)
                    Expanded(child: _StepCard(item: items[i], index: i, isFirst: i == 0, isLast: i == items.length - 1, disabled: completed || checking, onUp: () => _swap(i, i - 1), onDown: () => _swap(i, i + 1))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, height: 48, child: FilledButton.icon(onPressed: completed || checking ? null : _check, icon: const Icon(Icons.check_rounded), label: Text(completed ? 'تم الحل' : 'تحقق من الترتيب'))),
          ],
        ),
      ),
    );
  }
}

class _StepItem {
  const _StepItem(this.order, this.text, this.icon, this.color);
  final int order;
  final String text;
  final IconData icon;
  final Color color;
}

class _StepCard extends StatelessWidget {
  const _StepCard({required this.item, required this.index, required this.isFirst, required this.isLast, required this.disabled, required this.onUp, required this.onDown});
  final _StepItem item;
  final int index;
  final bool isFirst;
  final bool isLast;
  final bool disabled;
  final VoidCallback onUp;
  final VoidCallback onDown;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(children: <Widget>[
            CircleAvatar(radius: 18, backgroundColor: item.color.withAlpha(35), child: Icon(item.icon, color: item.color, size: 20)),
            const SizedBox(width: 10),
            Expanded(child: Text(item.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
            Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              SizedBox(width: 38, height: 30, child: IconButton(padding: EdgeInsets.zero, onPressed: disabled || isFirst ? null : onUp, icon: const Icon(Icons.keyboard_arrow_up_rounded))),
              SizedBox(width: 38, height: 30, child: IconButton(padding: EdgeInsets.zero, onPressed: disabled || isLast ? null : onDown, icon: const Icon(Icons.keyboard_arrow_down_rounded))),
            ]),
          ]),
        ),
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
      height: 86,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: <Color>[Color(0xFFEF4444), Color(0xFFF97316)])),
      child: Row(children: <Widget>[
        const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 38),
        const SizedBox(width: 12),
        Expanded(child: Text('رتّب خطوات القصة\nالنقاط: $score  •  المحاولات: $tries', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, fontFamily: 'Changa', color: Colors.white))),
      ]),
    );
  }
}
