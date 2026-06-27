import 'dart:math';
import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class PatternChallengePage extends StatefulWidget {
  const PatternChallengePage({super.key});
  @override
  State<PatternChallengePage> createState() => _PatternChallengePageState();
}

class _PatternChallengePageState extends State<PatternChallengePage> {
  final Random _random = Random();
  int score = 0;
  late List<_PatternShape> pattern;
  late _PatternShape answer;
  late List<_PatternShape> choices;

  final List<_PatternShape> shapes = const <_PatternShape>[
    _PatternShape(Icons.circle_rounded, Color(0xFFEF4444), 'دائرة'),
    _PatternShape(Icons.square_rounded, Color(0xFF3B82F6), 'مربع'),
    _PatternShape(Icons.star_rounded, Color(0xFFF59E0B), 'نجمة'),
    _PatternShape(Icons.favorite_rounded, Color(0xFFEC4899), 'قلب'),
  ];

  @override
  void initState() {
    super.initState();
    _round();
  }

  void _round() {
    final a = shapes[_random.nextInt(shapes.length)];
    _PatternShape b = shapes.where((_PatternShape s) => s.name != a.name).toList()[_random.nextInt(shapes.length - 1)];
    pattern = <_PatternShape>[a, b, a, b, a];
    answer = b;
    choices = List<_PatternShape>.from(shapes)..shuffle(_random);
    setState(() {});
  }

  Future<void> _pick(_PatternShape item) async {
    if (item.name == answer.name) {
      await ScoreService.instance.addStars(2);
      await SoundService.instance.play('chime.wav');
      if (!mounted) return;
      setState(() => score++);
      _round();
    } else {
      await SoundService.instance.play('wrong.wav');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('انظر للنمط مرة أخرى')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تحدي الأنماط')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
        children: <Widget>[
          _Banner(score: score),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
                for (final item in pattern) _ShapeBubble(shape: item, size: 52),
                Container(width: 56, height: 56, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(18)), child: const Icon(Icons.question_mark_rounded, size: 34)),
              ]),
            ),
          ),
          const SizedBox(height: 18),
          const Text('اختر الشكل الذي يكمل السلسلة', style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: choices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14),
            itemBuilder: (BuildContext context, int index) => Card(child: InkWell(borderRadius: BorderRadius.circular(24), onTap: () => _pick(choices[index]), child: Center(child: _ShapeBubble(shape: choices[index], size: 78)))),
          ),
        ],
      ),
    );
  }
}

class _PatternShape {
  const _PatternShape(this.icon, this.color, this.name);
  final IconData icon;
  final Color color;
  final String name;
}

class _ShapeBubble extends StatelessWidget {
  const _ShapeBubble({required this.shape, required this.size});
  final _PatternShape shape;
  final double size;
  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: shape.color.withAlpha(35), border: Border.all(color: shape.color.withAlpha(100), width: 2)), child: Icon(shape.icon, color: shape.color, size: size * 0.58));
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.score});
  final int score;
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors: <Color>[Color(0xFF0EA5E9), Color(0xFF7C3AED)])), child: Row(children: <Widget>[const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 42), const SizedBox(width: 14), Expanded(child: Text('أكمل النمط\nالنقاط: $score', style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 22, fontWeight: FontWeight.w900)))]));
  }
}
