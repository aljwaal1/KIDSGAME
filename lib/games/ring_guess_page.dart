import 'dart:math';
import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class RingGuessPage extends StatefulWidget {
  const RingGuessPage({super.key});

  @override
  State<RingGuessPage> createState() => _RingGuessPageState();
}

class _RingGuessPageState extends State<RingGuessPage> with SingleTickerProviderStateMixin {
  final Random random = Random();
  int ringIndex = 0;
  int score = 0;
  int tries = 0;
  bool revealed = false;
  String message = 'أين الخاتم؟ اختر يدًا';

  @override
  void initState() {
    super.initState();
    newRound();
  }

  void newRound() {
    setState(() {
      ringIndex = random.nextInt(5);
      revealed = false;
      message = 'أين الخاتم؟ اختر يدًا';
    });
  }

  Future<void> pick(int index) async {
    if (revealed) return;
    setState(() {
      tries++;
      revealed = true;
    });
    if (index == ringIndex) {
      await ScoreService.instance.addStars(2);
      await SoundService.instance.play('win.wav');
      if (!mounted) return;
      setState(() {
        score++;
        message = 'أحسنت! وجدت الخاتم';
      });
    } else {
      await SoundService.instance.play('wrong.wav');
      if (!mounted) return;
      setState(() => message = 'ليس هنا، كان الخاتم في يد أخرى');
    }
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) newRound();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الخاتم')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          children: <Widget>[
            _RingHeader(score: score, tries: tries, message: message),
            const SizedBox(height: 10),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cardW = (constraints.maxWidth - 16) / 2;
                  final cardH = (constraints.maxHeight - 16) / 3;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      for (var i = 0; i < 5; i++)
                        SizedBox(width: i == 4 ? constraints.maxWidth : cardW, height: cardH, child: _HandCard(index: i, hasRing: i == ringIndex, revealed: revealed, onTap: () => pick(i))),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            _RingHint(),
          ],
        ),
      ),
    );
  }
}

class _RingHeader extends StatelessWidget {
  const _RingHeader({required this.score, required this.tries, required this.message});
  final int score;
  final int tries;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors: <Color>[Color(0xFF7C2D12), Color(0xFFF59E0B)])),
      child: Row(children: <Widget>[
        const Icon(Icons.diamond_rounded, color: Colors.white, size: 42),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text(message, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 20, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text('النقاط: $score  •  المحاولات: $tries', style: const TextStyle(color: Color(0xFFFFF7D6), fontWeight: FontWeight.w700)),
        ])),
      ]),
    );
  }
}

class _HandCard extends StatelessWidget {
  const _HandCard({required this.index, required this.hasRing, required this.revealed, required this.onTap});
  final int index;
  final bool hasRing;
  final bool revealed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showRing = revealed && hasRing;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: <Color>[Color(0xFFFFF7ED), Color(0xFFFDE68A)])),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
            Text('${index + 1}', style: const TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            Icon(Icons.back_hand_rounded, color: showRing ? const Color(0xFFB45309) : const Color(0xFF92400E), size: 48),
            const SizedBox(height: 4),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: showRing ? const Icon(Icons.diamond_rounded, key: ValueKey<String>('ring'), color: Color(0xFFF59E0B), size: 32) : const SizedBox(key: ValueKey<String>('empty'), height: 32),
            ),
          ]),
        ),
      ),
    );
  }
}

class _RingHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 54, alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFFBBF24))), child: const Text('لعبة تخمين تراثية: اختر اليد التي تخبئ الخاتم.', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(0xFF78350F), fontWeight: FontWeight.w800)));
  }
}
