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
  final Random rnd = Random();
  final List<IconData> icons = <IconData>[Icons.star_rounded, Icons.favorite_rounded, Icons.circle, Icons.square_rounded, Icons.change_history_rounded];
  late IconData target;
  late List<IconData> options;
  int score = 0;
  @override
  void initState() { super.initState(); next(); }
  void next() { target = icons[rnd.nextInt(icons.length)]; options = List<IconData>.from(icons)..shuffle(); options = options.take(4).toList(); if (!options.contains(target)) options[0] = target; options.shuffle(); }
  void choose(IconData icon) { if (icon == target) { score++; ScoreService.instance.addStars(1); SoundService.instance.play('win.wav'); } else { SoundService.instance.play('wrong.wav'); } setState(next); }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('ظل الشكل - $score')), body: ListView(padding: const EdgeInsets.all(18), children: [
      const Text('اختر الشكل المطابق للظل', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 18),
      Center(child: Icon(target, size: 110, color: const Color(0xFF94A3B8))),
      const SizedBox(height: 24),
      GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: options.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14), itemBuilder: (context, i) => InkWell(onTap: () => choose(options[i]), child: Card(child: Center(child: Icon(options[i], size: 72, color: const Color(0xFF7C3AED))))))
    ]));
  }
}
