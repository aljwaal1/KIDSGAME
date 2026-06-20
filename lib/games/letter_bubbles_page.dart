import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/game_header.dart';

const List<String> _kArabicLetters = [
  'أ', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ', 'ر',
  'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع', 'غ', 'ف',
  'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و', 'ي',
];

class BubbleLettersPage extends StatefulWidget {
  const BubbleLettersPage({super.key});

  @override
  State<BubbleLettersPage> createState() => _BubbleLettersPageState();
}

class _BubbleLettersPageState extends State<BubbleLettersPage>
    with SingleTickerProviderStateMixin {
  final Random random = Random();
  late String target;
  late List<String> bubbles;
  late AnimationController driftController;
  int score = 0;
  int mistakes = 0;
  int streak = 0;
  int? bestStreak;
  final GlobalKey<ConfettiOverlayState> confettiKey =
      GlobalKey<ConfettiOverlayState>();

  @override
  void initState() {
    super.initState();
    driftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    createRound(resetScore: true);
    _loadBest();
  }

  Future<void> _loadBest() async {
    final value = await ScoreService.instance.getBestStreak('bubbles');
    if (mounted) setState(() => bestStreak = value);
  }

  @override
  void dispose() {
    driftController.dispose();
    super.dispose();
  }

  void createRound({bool resetScore = false}) {
    target = _kArabicLetters[random.nextInt(_kArabicLetters.length)];
    final bubbleCount = (3 + (score ~/ 5)).clamp(3, 6).toInt();
    bubbles = List.generate(
      bubbleCount,
      (_) => _kArabicLetters[random.nextInt(_kArabicLetters.length)],
    );
    bubbles[random.nextInt(bubbleCount)] = target;
    if (resetScore) {
      score = 0;
      mistakes = 0;
      streak = 0;
    }
  }

  void newRound({bool resetScore = false}) {
    createRound(resetScore: resetScore);
    setState(() {});
  }

  void pop(int index) {
    var shouldStartNewRound = false;
    setState(() {
      if (bubbles[index] == target) {
        SoundService.instance.play('pop.wav');
        HapticFeedback.lightImpact();
        score++;
        streak++;
        bubbles[index] = '';
        if (!bubbles.contains(target)) {
          shouldStartNewRound = true;
        }
      } else {
        SoundService.instance.play('wrong.wav');
        HapticFeedback.lightImpact();
        mistakes++;
        streak = 0;
      }
    });
    if (shouldStartNewRound) {
      SoundService.instance.play('chime.wav');
      confettiKey.currentState?.burst(count: 16);
      ScoreService.instance.addStars(1);
      ScoreService.instance.reportStreak('bubbles', streak).then((isNewBest) {
        if (isNewBest && mounted) setState(() => bestStreak = streak);
      });
      Future.delayed(const Duration(milliseconds: 280), () {
        if (mounted) newRound();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bestText =
        bestStreak != null && bestStreak! > 0 ? '  •  أفضل متتالية: $bestStreak' : '';
    return ConfettiOverlay(
      key: confettiKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          GameHeader(
            title: 'فقاعات الحروف',
            subtitle: 'النقاط: $score  •  متتالية: $streak$bestText',
            color: const Color(0xFF06B6D4),
            onReset: () => newRound(resetScore: true),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F7FA),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: const Color(0xFF67E8F9), width: 2),
            ),
            child: Column(
              children: [
                const Text(
                  'اضغط نفس الحرف',
                  style: TextStyle(
                    color: Color(0xFF0E7490),
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Changa',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  target,
                  style: const TextStyle(
                    color: Color(0xFF155E75),
                    fontSize: 88,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'الأخطاء: $mistakes',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: driftController,
            builder: (context, _) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: bubbles.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 18,
                ),
                itemBuilder: (context, index) {
                  final letter = bubbles[index];
                  final hidden = letter.isEmpty;
                  final direction = index.isEven ? 1.0 : -1.0;
                  final offset =
                      sin(driftController.value * pi * 2 + index) * 18 * direction;
                  return Transform.translate(
                    offset: Offset(offset, 0),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 180),
                      opacity: hidden ? 0.12 : 1,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: hidden ? null : () => pop(index),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: hidden
                                  ? [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)]
                                  : [const Color(0xFFA5F3FC), const Color(0xFF22D3EE)],
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                            ),
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x3306B6D4),
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned(
                                top: 14,
                                left: 18,
                                child: Container(
                                  width: 22,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(hidden ? 0.0 : 0.45),
                                  ),
                                ),
                              ),
                              Text(
                                letter,
                                style: const TextStyle(
                                  color: Color(0xFF164E63),
                                  fontSize: 50,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
