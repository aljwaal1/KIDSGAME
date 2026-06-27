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
  final Random rnd = Random();
  late int a;
  late int b;
  late int answer;
  int score = 0;
  @override
  void initState() { super.initState(); next(); }
  void next() { a = 1 + rnd.nextInt(9); b = 1 + rnd.nextInt(9); answer = a + b; }
  void choose(int n) { if (n == answer) { score++; ScoreService.instance.addStars(1); SoundService.instance.play('win.wav'); } else { SoundService.instance.play('wrong.wav'); } setState(next); }
  @override
  Widget build(BuildContext context) {
    final options = <int>{answer, answer + 1, max(0, answer - 1), answer + 2}.toList()..shuffle();
    return Scaffold(appBar: AppBar(title: Text('الحساب السريع - $score')), body: ListView(padding: const EdgeInsets.all(18), children: [
      Center(child: Text('$a + $b = ؟', style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900))),
      const SizedBox(height: 20),
      for (final o in options) Padding(padding: const EdgeInsets.only(bottom: 12), child: FilledButton(onPressed: () => choose(o), child: Text('$o', style: const TextStyle(fontSize: 28)))),
    ]));
  }
}
