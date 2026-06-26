import 'dart:math';

import 'package:flutter/material.dart';

import 'package:kids_games_arena/services/score_service.dart';
import 'package:kids_games_arena/services/sound_service.dart';

class MemoryPairsPage extends StatefulWidget {
  const MemoryPairsPage({super.key});

  @override
  State<MemoryPairsPage> createState() => _MemoryPairsPageState();
}

class _MemoryPairsPageState extends State<MemoryPairsPage> {
  static const _icons = [
    Icons.star_rounded,
    Icons.favorite_rounded,
    Icons.lightbulb_rounded,
    Icons.pets_rounded,
    Icons.rocket_launch_rounded,
    Icons.emoji_events_rounded,
  ];

  late List<IconData> _cards;
  final Set<int> _open = <int>{};
  final Set<int> _matched = <int>{};
  int _moves = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    final cards = <IconData>[..._icons, ..._icons]..shuffle(Random());
    setState(() {
      _cards = cards;
      _open.clear();
      _matched.clear();
      _moves = 0;
      _busy = false;
    });
  }

  Future<void> _tapCard(int index) async {
    if (_busy || _open.contains(index) || _matched.contains(index)) return;
    SoundService.instance.play('click.wav');
    setState(() => _open.add(index));
    if (_open.length == 2) {
      _busy = true;
      _moves++;
      final pair = _open.toList();
      await Future.delayed(const Duration(milliseconds: 450));
      if (_cards[pair[0]] == _cards[pair[1]]) {
        SoundService.instance.play('win.wav');
        setState(() {
          _matched.addAll(pair);
          _open.clear();
          _busy = false;
        });
        if (_matched.length == _cards.length) {
          await ScoreService.instance.addStars(_moves <= 10 ? 5 : 3);
          await ScoreService.instance.reportMoves('memory_pairs', _moves);
          if (!mounted) return;
          _showDone();
        }
      } else {
        SoundService.instance.play('wrong.wav');
        setState(() {
          _open.clear();
          _busy = false;
        });
      }
    }
  }

  void _showDone() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('رائع جدًا!'),
        content: Text('أنهيت لعبة الذاكرة خلال $_moves محاولة. حصلت على نجوم جديدة.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('حسنًا')),
          FilledButton(onPressed: () { Navigator.pop(context); _newRound(); }, child: const Text('جولة جديدة')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ذاكرة الصور')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _Header(moves: _moves, matched: _matched.length ~/ 2),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _cards.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemBuilder: (context, index) {
                final visible = _open.contains(index) || _matched.contains(index);
                final done = _matched.contains(index);
                return InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => _tapCard(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: visible
                          ? LinearGradient(colors: done ? const [Color(0xFF22C55E), Color(0xFF14B8A6)] : const [Color(0xFF8B5CF6), Color(0xFF06B6D4)])
                          : const LinearGradient(colors: [Color(0xFFFFE4E6), Color(0xFFFFFBEB)]),
                      boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 3))],
                    ),
                    child: Center(
                      child: Icon(
                        visible ? _cards[index] : Icons.question_mark_rounded,
                        size: 34,
                        color: visible ? Colors.white : const Color(0xFFBE185D),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _newRound,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة اللعبة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.moves, required this.matched});
  final int moves;
  final int matched;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)]),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology_rounded, color: Colors.white, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('تذكّر مكان الصور المتشابهة', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, fontFamily: 'Changa')),
                const SizedBox(height: 5),
                Text('المحاولات: $moves  •  الأزواج: $matched / 6', style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
