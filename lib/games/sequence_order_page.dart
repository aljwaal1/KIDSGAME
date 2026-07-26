import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class SequenceOrderPage extends StatefulWidget {
  const SequenceOrderPage({super.key});

  @override
  State<SequenceOrderPage> createState() => _SequenceOrderPageState();
}

class _SequenceOrderPageState extends State<SequenceOrderPage> {
  List<_StepItem> items = <_StepItem>[];
  int score = 0;
  int tries = 0;
  bool completed = false;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    _reset(playSound: false);
  }

  List<_StepItem> _freshItems() => <_StepItem>[
    const _StepItem(3, 'نخرجها من الفرن', Icons.local_fire_department_rounded, Color(0xFFEF4444)),
    const _StepItem(1, 'نجهّز العجينة', Icons.bakery_dining_rounded, Color(0xFFF59E0B)),
    const _StepItem(4, 'نأكلها مع العائلة', Icons.emoji_food_beverage_rounded, Color(0xFF22C55E)),
    const _StepItem(2, 'نضعها في الفرن', Icons.countertops_rounded, Color(0xFF3B82F6)),
  ]..shuffle();

  bool get solved {
    for (int i = 0; i < items.length; i++) {
      if (items[i].order != i + 1) return false;
    }
    return true;
  }

  void _reset({bool playSound = true}) {
    setState(() {
      items = _freshItems();
      tries = 0;
      completed = false;
      busy = false;
    });
    if (playSound) SoundService.instance.play('click.wav');
  }

  void _swap(int from, int to) {
    if (completed || busy || to < 0 || to >= items.length) return;
    setState(() {
      final _StepItem temp = items[from];
      items[from] = items[to];
      items[to] = temp;
    });
    SoundService.instance.play('move.wav');
  }

  Future<void> _check() async {
    if (completed || busy) return;
    busy = true;
    setState(() => tries++);
    try {
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
    } finally {
      busy = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = !completed && !busy;
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
            Text(completed ? 'اكتمل الترتيب بنجاح 🎉' : 'رتّب القصة بالأسهم من البداية للنهاية', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: completed ? const Color(0xFF16A34A) : const Color(0xFF64748B), fontSize: 14, fontWeight: completed ? FontWeight.w800 : FontWeight.normal)),
            const SizedBox(height: 8),
            Expanded(
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < items.length; i++)
                    Expanded(child: _StepCard(item: items[i], index: i, enabled: canEdit, isFirst: i == 0, isLast: i == items.length - 1, onUp: () => _swap(i, i - 1), onDown: () => _swap(i, i + 1))),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: completed
                  ? FilledButton.icon(onPressed: _reset, icon: const Icon(Icons.replay_rounded), label: const Text('جولة جديدة'))
                  : FilledButton.icon(onPressed: busy ? null : _check, icon: const Icon(Icons.check_rounded), label: const Text('تحقق من الترتيب')),
            ),
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
  const _StepCard({required this.item, required this.index, required this.enabled, required this.isFirst, required this.isLast, required this.onUp, required this.onDown});
  final _StepItem item;
  final int index;
  final bool enabled;
  final bool isFirst;
  final bool isLast;
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
              SizedBox(width: 38, height: 30, child: IconButton(padding: EdgeInsets.zero, onPressed: !enabled || isFirst ? null : onUp, icon: const Icon(Icons.keyboard_arrow_up_rounded))),
              SizedBox(width: 38, height: 30, child: IconButton(padding: EdgeInsets.zero, onPressed: !enabled || isLast ? null : onDown, icon: const Icon(Icons.keyboard_arrow_down_rounded))),
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
