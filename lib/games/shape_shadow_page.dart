import 'dart:math';
import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class ShapeShadowPage extends StatefulWidget {
  const ShapeShadowPage({super.key});

  @override
  State<ShapeShadowPage> createState() => _ShapeShadowPageState();
}

class _ShapeShadowPageState extends State<ShapeShadowPage> {
  final Random _random = Random();
  int score = 0;
  late _ShapeItem target;
  late List<_ShapeItem> choices;

  final List<_ShapeItem> bank = const <_ShapeItem>[
    _ShapeItem('نجمة', Icons.star_rounded, Color(0xFFF59E0B)),
    _ShapeItem('قلب', Icons.favorite_rounded, Color(0xFFEC4899)),
    _ShapeItem('منزل', Icons.home_rounded, Color(0xFF22C55E)),
    _ShapeItem('سيارة', Icons.directions_car_rounded, Color(0xFF3B82F6)),
    _ShapeItem('زهرة', Icons.local_florist_rounded, Color(0xFF8B5CF6)),
  ];

  @override
  void initState() {
    super.initState();
    _round();
  }

  void _round() {
    final shuffled = List<_ShapeItem>.from(bank)..shuffle(_random);
    target = shuffled.first;
    choices = shuffled.take(4).toList()..shuffle(_random);
    setState(() {});
  }

  Future<void> _pick(_ShapeItem item) async {
    if (item.name == target.name) {
      await SoundService.instance.play('chime.wav');
      await ScoreService.instance.addStars(2);
      if (!mounted) return;
      setState(() => score++);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('أحسنت! هذا هو الظل الصحيح')));
      Future<void>.delayed(const Duration(milliseconds: 450), _round);
    } else {
      await SoundService.instance.play('wrong.wav');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ليس هذا، جرّب ظلًا آخر')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ظل الشكل')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          children: <Widget>[
            _ShadowHeader(score: score),
            const SizedBox(height: 10),
            Card(
              child: SizedBox(
                height: 108,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                  Icon(target.icon, color: target.color, size: 70),
                  const SizedBox(width: 18),
                  Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    const Text('ابحث عن ظل الشكل', style: TextStyle(fontFamily: 'Changa', fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(target.name, style: const TextStyle(fontSize: 17, color: Color(0xFF64748B))),
                  ]),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: choices.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10),
                itemBuilder: (BuildContext context, int index) {
                  final item = choices[index];
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => _pick(item),
                      child: Container(
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: const Color(0xFFF1F5F9)),
                        child: Icon(item.icon, color: const Color(0xFF475569), size: 70),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShapeItem {
  const _ShapeItem(this.name, this.icon, this.color);
  final String name;
  final IconData icon;
  final Color color;
}

class _ShadowHeader extends StatelessWidget {
  const _ShadowHeader({required this.score});
  final int score;
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: <Color>[Color(0xFF8B5CF6), Color(0xFFEC4899)])),
      child: Row(children: <Widget>[
        const Icon(Icons.filter_vintage_rounded, color: Colors.white, size: 38),
        const SizedBox(width: 12),
        Expanded(child: Text('طابق الشكل مع ظله\nالنقاط: $score', style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 19, fontWeight: FontWeight.w900))),
      ]),
    );
  }
}
