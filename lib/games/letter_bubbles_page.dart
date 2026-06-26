import 'dart:math';
import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class BubbleLettersPage extends StatefulWidget {
  const BubbleLettersPage({super.key});

  @override
  State<BubbleLettersPage> createState() => _BubbleLettersPageState();
}

class _BubbleLettersPageState extends State<BubbleLettersPage> {
  final rnd = Random();
  final letters = ['أ', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ر', 'س'];
  late String target;
  late List<String> bubbles;
  int streak = 0;

  @override
  void initState() {
    super.initState();
    _round();
  }

  void _round() {
    target = letters[rnd.nextInt(letters.length)];
    bubbles = List.generate(8, (_) => letters[rnd.nextInt(letters.length)]);
    bubbles[rnd.nextInt(bubbles.length)] = target;
  }

  void _tap(String letter) async {
    if (letter == target) {
      streak++;
      await ScoreService.instance.addStars(1);
      await ScoreService.instance.reportStreak('letters', streak);
      await SoundService.instance.play('win.wav');
      setState(_round);
    } else {
      streak = 0;
      await SoundService.instance.play('wrong.wav');
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: const Color(0xFF06B6D4), borderRadius: BorderRadius.circular(24)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('فقاعات الحروف', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Changa')),
            const SizedBox(height: 8),
            Text('اضغط حرف: $target   •   التتابع: $streak', style: const TextStyle(color: Color(0xFFFFF7D6))),
          ]),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: bubbles.map((l) => InkWell(
            onTap: () => _tap(l),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF7C3AED)]),
                boxShadow: [BoxShadow(color: const Color(0xFF06B6D4).withOpacity(0.24), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              alignment: Alignment.center,
              child: Text(l, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, fontFamily: 'Changa')),
            ),
          )).toList(),
        ),
      ],
    );
  }
}
