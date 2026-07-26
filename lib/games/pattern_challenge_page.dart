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
  bool answering = false;

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
    final alternatives = shapes.where((_PatternShape s) => s.name != a.name).toList();
    final b = alternatives[_random.nextInt(alternatives.length)];
    pattern = <_PatternShape>[a, b, a, b, a];
    answer = b;
    choices = List<_PatternShape>.from(shapes)..shuffle(_random);
    setState(() {});
  }

  Future<void> _pick(_PatternShape item) async {
    if (answering) return;
    setState(() => answering = true);
    try {
      if (item.name == answer.name) {
        await ScoreService.instance.addStars(2);
        await SoundService.instance.play('chime.wav');
        if (!mounted) return;
        setState(() => score++);
        _round();
      } else {
        await SoundService.instance.play('wrong.wav');
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('انظر للنمط مرة أخرى')));
      }
    } finally {
      if (mounted) setState(() => answering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تحدي الأنماط')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          children: <Widget>[
            _Banner(score: score),
            const SizedBox(height: 10),
            Card(
              child: SizedBox(
                height: 82,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: <Widget>[
                    for (final item in pattern) _ShapeBubble(shape: item, size: 42),
                    Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.question_mark_rounded, size: 28)),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(answering ? 'جارٍ التحقق...' : 'اختر الشكل الذي يكمل السلسلة', style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: choices.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10),
                itemBuilder: (BuildContext context, int index) => Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: answering ? null : () => _pick(choices[index]),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 150),
                      opacity: answering ? 0.72 : 1,
                      child: Center(child: _ShapeBubble(shape: choices[index], size: 66)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
    return Container(height: 88, padding: const EdgeInsets.all(16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: <Color>[Color(0xFF0EA5E9), Color(0xFF7C3AED)])), child: Row(children: <Widget>[const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 38), const SizedBox(width: 12), Expanded(child: Text('أكمل النمط\nالنقاط: $score', style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 20, fontWeight: FontWeight.w900)))]));
  }
}
