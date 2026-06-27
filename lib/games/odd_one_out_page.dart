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
  int _score = 0;
  int _round = 1;
  late List<String> _items;
  late int _answerIndex;
  String _message = 'اختر الشكل المختلف';

  static const List<List<String>> _sets = [
    ['🍎', '🍎', '🍎', '🍌'],
    ['⭐', '⭐', '⭐', '🌙'],
    ['🐱', '🐱', '🐱', '🐶'],
    ['🚗', '🚗', '🚗', '✈️'],
    ['🔵', '🔵', '🔵', '🔴'],
    ['🟦', '🟦', '🟦', '🟨'],
  ];

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    final base = List<String>.from(_sets[_random.nextInt(_sets.length)]);
    final odd = base.last;
    base.shuffle(_random);
    setState(() {
      _items = base;
      _answerIndex = base.indexOf(odd);
      _message = 'اختر الشكل المختلف';
    });
  }

  void _pick(int index) {
    if (index == _answerIndex) {
      SoundService.instance.play('win.wav');
      ScoreService.instance.addStars(1);
      setState(() {
        _score++;
        _round++;
        _message = 'ممتاز! هذا هو المختلف 🎉';
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _newRound();
      });
    } else {
      SoundService.instance.play('wrong.wav');
      setState(() => _message = 'جرّب مرة أخرى');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ابحث عن المختلف')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _Header(message: _message, score: _score, round: _round),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (context, index) {
              return InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => _pick(index),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(_items[index], style: const TextStyle(fontSize: 54)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.message, required this.score, required this.round});

  final String message;
  final int score;
  final int round;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Changa')),
          const SizedBox(height: 8),
          Text('الجولة: $round  •  النقاط: $score', style: const TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
