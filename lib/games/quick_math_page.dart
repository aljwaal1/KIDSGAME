import 'dart:math';
import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class QuickMathPage extends StatefulWidget {
  const QuickMathPage({super.key});
  @override
  State<QuickMathPage> createState() => _QuickMathPageState();
}

class _QuickMathPageState extends State<QuickMathPage> {
  final Random _random = Random();
  int a = 2;
  int b = 3;
  bool plus = true;
  int score = 0;
  late List<int> options;

  int get answer => plus ? a + b : a - b;

  @override
  void initState() {
    super.initState();
    _round();
  }

  void _round() {
    a = 2 + _random.nextInt(9);
    b = 1 + _random.nextInt(8);
    plus = _random.nextBool();
    if (!plus && b > a) {
      final int t = a;
      a = b;
      b = t;
    }
    final Set<int> set = <int>{answer};
    while (set.length < 4) {
      set.add((answer + _random.nextInt(7) - 3).clamp(0, 20));
    }
    options = set.toList()..shuffle(_random);
    setState(() {});
  }

  Future<void> _pick(int value) async {
    if (value == answer) {
      await SoundService.instance.play('pop.wav');
      await ScoreService.instance.addStars(1);
      if (!mounted) return;
      setState(() => score++);
      _round();
    } else {
      await SoundService.instance.play('wrong.wav');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حاول مرة أخرى')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الحساب السريع')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: const LinearGradient(colors: <Color>[Color(0xFF7C3AED), Color(0xFF0EA5E9)])),
            child: Column(children: <Widget>[
              const Icon(Icons.calculate_rounded, color: Colors.white, size: 48),
              const SizedBox(height: 8),
              Text('$a ${plus ? '+' : '-'} $b = ؟', style: const TextStyle(color: Colors.white, fontSize: 44, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text('النقاط: $score', style: const TextStyle(color: Color(0xFFFFF7D6))),
            ]),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: options.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 1.35),
            itemBuilder: (BuildContext context, int index) => FilledButton.tonal(onPressed: () => _pick(options[index]), child: Text('${options[index]}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900))),
          ),
        ],
      ),
    );
  }
}
