import 'dart:math';
import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class OddOneOutPage extends StatefulWidget {
  const OddOneOutPage({super.key});

  @override
  State<OddOneOutPage> createState() => _OddOneOutPageState();
}

class _OddOneOutPageState extends State<OddOneOutPage> {
  final Random _random = Random();
  int level = 1;
  int score = 0;
  late List<_OddItem> items;
  late int correctIndex;

  final List<List<_OddItem>> sets = <List<_OddItem>>[
    <_OddItem>[
      _OddItem('تفاح', Icons.apple_rounded, Color(0xFFEF4444), 'فاكهة'),
      _OddItem('برتقال', Icons.circle_rounded, Color(0xFFF97316), 'فاكهة'),
      _OddItem('موز', Icons.eco_rounded, Color(0xFFFACC15), 'فاكهة'),
      _OddItem('سيارة', Icons.directions_car_rounded, Color(0xFF3B82F6), 'مركبة'),
    ],
    <_OddItem>[
      _OddItem('قطة', Icons.pets_rounded, Color(0xFFF59E0B), 'حيوان'),
      _OddItem('كلب', Icons.pets_rounded, Color(0xFF8B5CF6), 'حيوان'),
      _OddItem('طائر', Icons.flutter_dash_rounded, Color(0xFF06B6D4), 'حيوان'),
      _OddItem('قلم', Icons.edit_rounded, Color(0xFF10B981), 'أداة'),
    ],
    <_OddItem>[
      _OddItem('دائرة', Icons.circle_rounded, Color(0xFF22C55E), 'مستدير'),
      _OddItem('كرة', Icons.sports_soccer_rounded, Color(0xFF16A34A), 'مستدير'),
      _OddItem('قمر', Icons.nightlight_round, Color(0xFFFBBF24), 'مستدير'),
      _OddItem('مربع', Icons.square_rounded, Color(0xFFEC4899), 'زوايا'),
    ],
  ];

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    final source = List<_OddItem>.from(sets[_random.nextInt(sets.length)]);
    source.shuffle(_random);
    setState(() {
      items = source;
      correctIndex = items.indexWhere((_OddItem item) => item.label == 'سيارة' || item.label == 'قلم' || item.label == 'مربع');
    });
  }

  Future<void> _answer(int index) async {
    if (index == correctIndex) {
      await SoundService.instance.play('win.wav');
      await ScoreService.instance.addStars(2);
      if (!mounted) return;
      setState(() {
        score++;
        level++;
      });
      _show('رائع! وجدت المختلف ⭐');
      Future<void>.delayed(const Duration(milliseconds: 450), _newRound);
    } else {
      await SoundService.instance.play('wrong.wav');
      if (!mounted) return;
      _show('حاول مرة أخرى، ركّز في المجموعة');
    }
  }

  void _show(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ابحث عن المختلف')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
        children: <Widget>[
          _TopCard(title: 'أي صورة لا تشبه الباقي؟', subtitle: 'النقاط: $score  •  المستوى: $level', icon: Icons.visibility_rounded, color: const Color(0xFF14B8A6)),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14),
            itemBuilder: (BuildContext context, int index) {
              final item = items[index];
              return _PictureButton(item: item, onTap: () => _answer(index));
            },
          ),
        ],
      ),
    );
  }
}

class _OddItem {
  const _OddItem(this.label, this.icon, this.color, this.group);
  final String label;
  final IconData icon;
  final Color color;
  final String group;
}

class _PictureButton extends StatelessWidget {
  const _PictureButton({required this.item, required this.onTap});
  final _OddItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(colors: <Color>[item.color.withAlpha(45), Colors.white], begin: Alignment.topRight, end: Alignment.bottomLeft),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(shape: BoxShape.circle, color: item.color.withAlpha(35), border: Border.all(color: item.color.withAlpha(90), width: 2)),
                child: Icon(item.icon, color: item.color, size: 42),
              ),
              const SizedBox(height: 10),
              Text(item.label, style: const TextStyle(fontFamily: 'Changa', fontSize: 20, fontWeight: FontWeight.w800)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopCard extends StatelessWidget {
  const _TopCard({required this.title, required this.subtitle, required this.icon, required this.color});
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: LinearGradient(colors: <Color>[color, color.withAlpha(190)])),
      child: Row(children: <Widget>[
        Icon(icon, color: Colors.white, size: 42),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Text(title, style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Color(0xFFFFF7D6))),
        ])),
      ]),
    );
  }
}
