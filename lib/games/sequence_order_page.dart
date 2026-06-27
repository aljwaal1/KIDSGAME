import 'dart:math';

import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class SequenceOrderPage extends StatefulWidget {
  const SequenceOrderPage({super.key});

  @override
  State<SequenceOrderPage> createState() => _SequenceOrderPageState();
}

class _SequenceOrderPageState extends State<SequenceOrderPage> {
  final Random _random = Random();
  int _score = 0;
  late List<int> _correct;
  late List<int> _current;
  String _message = 'رتّب الأرقام من الأصغر إلى الأكبر';

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    final start = 1 + _random.nextInt(5);
    final numbers = List<int>.generate(4, (i) => start + i);
    final mixed = List<int>.from(numbers)..shuffle(_random);
    setState(() {
      _correct = numbers;
      _current = mixed;
      _message = 'رتّب الأرقام من الأصغر إلى الأكبر';
    });
  }

  void _check() {
    final ok = _current.join(',') == _correct.join(',');
    if (ok) {
      SoundService.instance.play('win.wav');
      ScoreService.instance.addStars(2);
      setState(() {
        _score++;
        _message = 'ترتيب صحيح 🎉';
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _newRound();
      });
    } else {
      SoundService.instance.play('wrong.wav');
      setState(() => _message = 'حرّك البطاقات حتى يصبح الترتيب صحيحًا');
    }
  }

  void _swap(int from, int to) {
    setState(() {
      final item = _current.removeAt(from);
      _current.insert(to > from ? to - 1 : to, item);
    });
    SoundService.instance.play('click.wav');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('رتّب التسلسل')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_message, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, fontFamily: 'Changa')),
                const SizedBox(height: 8),
                Text('النقاط: $_score', style: const TextStyle(color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(height: 18),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _current.length,
            onReorder: _swap,
            itemBuilder: (context, index) {
              final number = _current[index];
              return Card(
                key: ValueKey(number),
                child: ListTile(
                  leading: const Icon(Icons.drag_indicator_rounded),
                  title: Text(
                    '$number',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _check,
            icon: const Icon(Icons.check_rounded),
            label: const Text('تحقق من الترتيب'),
          ),
        ],
      ),
    );
  }
}
