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
  final _rng = Random();
  int _score = 0;
  int _round = 1;
  late _MathQuestion _question;

  @override
  void initState() {
    super.initState();
    _question = _makeQuestion();
  }

  _MathQuestion _makeQuestion() {
    final max = _round < 5 ? 10 : 20;
    final a = 1 + _rng.nextInt(max);
    final b = 1 + _rng.nextInt(max);
    final plus = _rng.nextBool() || a < b;
    final answer = plus ? a + b : a - b;
    final choices = <int>{answer};
    while (choices.length < 4) {
      choices.add(answer + _rng.nextInt(9) - 4);
    }
    return _MathQuestion('$a ${plus ? '+' : '-'} $b', answer, choices.toList()..shuffle(_rng));
  }

  Future<void> _answer(int value) async {
    if (value == _question.answer) {
      SoundService.instance.play('win.wav');
      _score++;
      _round++;
      if (_score % 5 == 0) await ScoreService.instance.addStars(3);
      setState(() => _question = _makeQuestion());
    } else {
      SoundService.instance.play('wrong.wav');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('قريب جدًا، جرّب مرة أخرى')));
    }
  }

  void _reset() {
    setState(() {
      _score = 0;
      _round = 1;
      _question = _makeQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الحساب السريع')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFFEC4899)])),
              child: Row(
                children: [
                  const Icon(Icons.calculate_rounded, color: Colors.white, size: 46),
                  const SizedBox(width: 12),
                  Expanded(child: Text('حلّ العملية واختر الإجابة\nالنقاط $_score', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Changa'))),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 30),
              decoration: BoxDecoration(color: const Color(0xFFFFFBEB), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFFDE68A))),
              child: Center(child: Text(_question.text, textDirection: TextDirection.ltr, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFF92400E)))),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,
              children: _question.choices.map((choice) {
                return FilledButton(
                  onPressed: () => _answer(choice),
                  child: Text('$choice', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(onPressed: _reset, icon: const Icon(Icons.refresh_rounded), label: const Text('إعادة النقاط')),
          ],
        ),
      ),
    );
  }
}

class _MathQuestion {
  const _MathQuestion(this.text, this.answer, this.choices);
  final String text;
  final int answer;
  final List<int> choices;
}
