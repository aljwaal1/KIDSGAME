import 'dart:math';

import 'package:flutter/material.dart';

import 'package:kids_games_arena/services/score_service.dart';
import 'package:kids_games_arena/services/sound_service.dart';

class PatternChallengePage extends StatefulWidget {
  const PatternChallengePage({super.key});

  @override
  State<PatternChallengePage> createState() => _PatternChallengePageState();
}

class _PatternChallengePageState extends State<PatternChallengePage> {
  final _rng = Random();
  int _level = 1;
  int _score = 0;
  late _PatternQuestion _question;

  static const _items = [
    _PatternItem(Icons.circle_rounded, Color(0xFFEF4444), 'دائرة حمراء'),
    _PatternItem(Icons.square_rounded, Color(0xFF3B82F6), 'مربع أزرق'),
    _PatternItem(Icons.star_rounded, Color(0xFFF59E0B), 'نجمة صفراء'),
    _PatternItem(Icons.favorite_rounded, Color(0xFFEC4899), 'قلب وردي'),
  ];

  @override
  void initState() {
    super.initState();
    _question = _makeQuestion();
  }

  _PatternQuestion _makeQuestion() {
    final patternSize = _level < 4 ? 2 : 3;
    final base = List.generate(patternSize, (_) => _items[_rng.nextInt(_items.length)]);
    final length = _level < 5 ? 5 : 6;
    final sequence = List.generate(length, (i) => base[i % base.length]);
    final missingIndex = 1 + _rng.nextInt(length - 2);
    final answer = sequence[missingIndex];
    final choices = <_PatternItem>{answer};
    while (choices.length < 4) {
      choices.add(_items[_rng.nextInt(_items.length)]);
    }
    return _PatternQuestion(sequence, missingIndex, answer, choices.toList()..shuffle(_rng));
  }

  Future<void> _answer(_PatternItem item) async {
    if (item == _question.answer) {
      SoundService.instance.play('win.wav');
      _score++;
      if (_score % 3 == 0) {
        await ScoreService.instance.addStars(2);
      }
      setState(() {
        _level++;
        _question = _makeQuestion();
      });
    } else {
      SoundService.instance.play('wrong.wav');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فكّر في الترتيب وحاول مرة أخرى')),
      );
    }
  }

  void _reset() {
    SoundService.instance.play('click.wav');
    setState(() {
      _level = 1;
      _score = 0;
      _question = _makeQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('تحدي الأنماط')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF22C55E)]),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('اختر الشكل الناقص في السلسلة\nالمستوى $_level • النقاط $_score', style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, fontFamily: 'Changa')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE2E8F0))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_question.sequence.length, (index) {
                  if (index == _question.missingIndex) {
                    return const _PatternSlot(child: Icon(Icons.help_rounded, color: Color(0xFF64748B), size: 34));
                  }
                  return _PatternSlot(child: _question.sequence[index].iconWidget(size: 34));
                }),
              ),
            ),
            const SizedBox(height: 22),
            const Text('الاختيارات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Changa')),
            const SizedBox(height: 12),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.8,
              children: _question.choices.map((item) {
                return FilledButton.tonalIcon(
                  onPressed: () => _answer(item),
                  icon: item.iconWidget(size: 24),
                  label: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(onPressed: _reset, icon: const Icon(Icons.refresh_rounded), label: const Text('من البداية')),
          ],
        ),
      ),
    );
  }
}

class _PatternSlot extends StatelessWidget {
  const _PatternSlot({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 58,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Center(child: child),
    );
  }
}

class _PatternItem {
  const _PatternItem(this.icon, this.color, this.name);
  final IconData icon;
  final Color color;
  final String name;
  Widget iconWidget({double size = 30}) => Icon(icon, color: color, size: size);
}

class _PatternQuestion {
  const _PatternQuestion(this.sequence, this.missingIndex, this.answer, this.choices);
  final List<_PatternItem> sequence;
  final int missingIndex;
  final _PatternItem answer;
  final List<_PatternItem> choices;
}
