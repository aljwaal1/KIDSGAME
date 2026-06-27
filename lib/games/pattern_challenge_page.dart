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
  final Random rnd = Random();
  final List<String> shapes = <String>['🔴','🔵','🟢','🟡','⭐','❤️'];
  late List<String> sequence;
  late String answer;
  int score = 0;

  @override
  void initState() { super.initState(); newRound(); }
  void newRound() {
    final a = shapes[rnd.nextInt(shapes.length)];
    String b = shapes[rnd.nextInt(shapes.length)];
    while (b == a) { b = shapes[rnd.nextInt(shapes.length)]; }
    sequence = <String>[a, b, a, b, a, '?'];
    answer = b;
  }

  void choose(String value) {
    if (value == answer) { score++; ScoreService.instance.addStars(1); SoundService.instance.play('win.wav'); }
    else { SoundService.instance.play('wrong.wav'); }
    setState(newRound);
  }

  @override
  Widget build(BuildContext context) {
    final options = <String>{answer, ...shapes.take(4)}.toList()..shuffle();
    return Scaffold(
      appBar: AppBar(title: Text('تحدي الأنماط - $score')),
      body: ListView(padding: const EdgeInsets.all(18), children: [
        const Text('اختر الشكل الناقص في آخر السلسلة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 18),
        Wrap(spacing: 10, runSpacing: 10, alignment: WrapAlignment.center, children: [for (final s in sequence) Chip(label: Text(s, style: const TextStyle(fontSize: 34)))]),
        const SizedBox(height: 26),
        for (final o in options) Padding(padding: const EdgeInsets.only(bottom: 12), child: FilledButton(onPressed: () => choose(o), child: Text(o, style: const TextStyle(fontSize: 30)))),
      ]),
    );
  }
}
