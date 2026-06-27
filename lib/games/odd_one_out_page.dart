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
  final Random rnd = Random();
  final List<List<String>> sets = <List<String>>[
    <String>['🍎','🍎','🍎','🍌'], <String>['⭐','⭐','❤️','⭐'], <String>['🐱','🐱','🐶','🐱'], <String>['🔵','🔵','🔴','🔵'],
  ];
  late List<String> items;
  late int answer;
  int score = 0;
  @override
  void initState() { super.initState(); next(); }
  void next() { items = List<String>.from(sets[rnd.nextInt(sets.length)]); items.shuffle(); final counts = <String, int>{}; for (final x in items) { counts[x] = (counts[x] ?? 0) + 1; } answer = items.indexWhere((x) => counts[x] == 1); }
  void choose(int i) { if (i == answer) { score++; ScoreService.instance.addStars(1); SoundService.instance.play('win.wav'); } else { SoundService.instance.play('wrong.wav'); } setState(next); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('ابحث عن المختلف - $score')), body: GridView.builder(padding: const EdgeInsets.all(18), itemCount: items.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14), itemBuilder: (context, i) => InkWell(onTap: () => choose(i), borderRadius: BorderRadius.circular(22), child: Card(child: Center(child: Text(items[i], style: const TextStyle(fontSize: 54)))))));
  }
}
