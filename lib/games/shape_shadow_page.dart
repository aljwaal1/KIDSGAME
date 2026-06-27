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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
        children: <Widget>[
          _ShadowHeader(score: score),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(children: <Widget>[
                const Text('ابحث عن ظل هذا الشكل', style: TextStyle(fontFamily: 'Changa', fontSize: 21, fontWeight: FontWeight.w800)),
                const SizedBox(height: 18),
                Icon(target.icon, color: target.color, size: 92),
                const SizedBox(height: 8),
                Text(target.name, style: const TextStyle(fontSize: 18, color: Color(0xFF64748B))),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: choices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14),
            itemBuilder: (BuildContext context, int index) {
              final item = choices[index];
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => _pick(item),
                  child: Container(
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: const Color(0xFFF1F5F9)),
                    child: Icon(item.icon, color: const Color(0xFF475569), size: 82),
                  ),
                ),
              );
            },
          ),
        ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors: <Color>[Color(0xFF8B5CF6), Color(0xFFEC4899)])),
      child: Row(children: <Widget>[
        const Icon(Icons.filter_vintage_rounded, color: Colors.white, size: 42),
        const SizedBox(width: 14),
        Expanded(child: Text('طابق الشكل مع ظله\nالنقاط: $score', style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 21, fontWeight: FontWeight.w900))),
      ]),
    );
  }
}
