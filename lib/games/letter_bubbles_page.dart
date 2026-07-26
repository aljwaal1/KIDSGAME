import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/score_service.dart';
import '../services/sound_service.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/game_header.dart';

const List<String> _arabicLetters = <String>['أ','ب','ت','ث','ج','ح','خ','د','ذ','ر','ز','س','ش','ص','ض','ط','ظ','ع','غ','ف','ق','ك','ل','م','ن','ه','و','ي'];

class BubbleLettersPage extends StatefulWidget {
  const BubbleLettersPage({super.key});
  @override
  State<BubbleLettersPage> createState() => _BubbleLettersPageState();
}

class _BubbleLettersPageState extends State<BubbleLettersPage> with SingleTickerProviderStateMixin {
  final Random random = Random();
  late String target;
  late List<String> bubbles;
  late AnimationController driftController;
  int score = 0;
  int mistakes = 0;
  int streak = 0;
  int? bestStreak;
  bool transitioning = false;
  Timer? _roundTimer;
  final GlobalKey<ConfettiOverlayState> confettiKey = GlobalKey<ConfettiOverlayState>();

  @override
  void initState() { super.initState(); driftController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat(reverse: true); createRound(resetScore: true); _loadBest(); }
  Future<void> _loadBest() async { final value = await ScoreService.instance.getBestStreak('bubbles'); if (mounted) setState(() => bestStreak = value); }
  @override
  void dispose() { _roundTimer?.cancel(); driftController.dispose(); super.dispose(); }

  void createRound({bool resetScore = false}) {
    target = _arabicLetters[random.nextInt(_arabicLetters.length)];
    final count = (3 + (score ~/ 5)).clamp(3, 6).toInt();
    bubbles = List<String>.generate(count, (_) => _arabicLetters[random.nextInt(_arabicLetters.length)]);
    bubbles[random.nextInt(count)] = target;
    transitioning = false;
    if (resetScore) { score = 0; mistakes = 0; streak = 0; }
  }

  void newRound({bool resetScore = false}) {
    _roundTimer?.cancel();
    createRound(resetScore: resetScore);
    setState(() {});
  }

  void pop(int index) {
    if (transitioning) return;
    var next = false;
    setState(() {
      if (bubbles[index] == target) {
        SoundService.instance.play('pop.wav'); HapticFeedback.lightImpact(); score++; streak++; bubbles[index] = '';
        if (!bubbles.contains(target)) {
          next = true;
          transitioning = true;
        }
      } else { SoundService.instance.play('wrong.wav'); HapticFeedback.lightImpact(); mistakes++; streak = 0; }
    });
    if (next) {
      final completedStreak = streak;
      SoundService.instance.play('chime.wav'); confettiKey.currentState?.burst(count: 16); ScoreService.instance.addStars(1);
      ScoreService.instance.reportStreak('bubbles', completedStreak).then((ok) { if (ok && mounted) setState(() => bestStreak = completedStreak); });
      _roundTimer = Timer(const Duration(milliseconds: 320), () { if (mounted) newRound(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bestText = bestStreak != null && bestStreak! > 0 ? '  •  أفضل: $bestStreak' : '';
    return ConfettiOverlay(
      key: confettiKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
        child: Column(
          children: <Widget>[
            GameHeader(title: 'فقاعات الحروف', subtitle: transitioning ? 'أحسنت! الجولة التالية...' : 'النقاط: $score  •  متتالية: $streak$bestText', color: const Color(0xFF06B6D4), onReset: () => newRound(resetScore: true)),
            const SizedBox(height: 8),
            Container(
              height: 116,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(26), border: Border.all(color: const Color(0xFF67E8F9), width: 2)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
                const Text('اضغط نفس الحرف', style: TextStyle(color: Color(0xFF0E7490), fontWeight: FontWeight.w800, fontFamily: 'Changa')),
                const SizedBox(width: 18),
                Text(target, style: const TextStyle(color: Color(0xFF155E75), fontSize: 76, fontWeight: FontWeight.w900, height: 1)),
              ]),
            ),
            const SizedBox(height: 6),
            Align(alignment: AlignmentDirectional.centerStart, child: Text('الأخطاء: $mistakes', style: const TextStyle(color: Color(0xFF64748B)))),
            const SizedBox(height: 8),
            Expanded(
              child: AnimatedBuilder(
                animation: driftController,
                builder: (context, _) => GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bubbles.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
                  itemBuilder: (context, index) {
                    final letter = bubbles[index];
                    final hidden = letter.isEmpty;
                    final offset = sin(driftController.value * pi * 2 + index) * 10 * (index.isEven ? 1 : -1);
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 180),
                        opacity: hidden || transitioning ? 0.35 : 1,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: hidden || transitioning ? null : () => pop(index),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(colors: hidden ? const <Color>[Color(0xFFE2E8F0), Color(0xFFCBD5E1)] : const <Color>[Color(0xFFA5F3FC), Color(0xFF22D3EE)], begin: Alignment.topRight, end: Alignment.bottomLeft),
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x3306B6D4), blurRadius: 14, offset: Offset(0, 6))],
                            ),
                            child: Center(child: Text(letter, style: const TextStyle(color: Color(0xFF164E63), fontSize: 42, fontWeight: FontWeight.w900))),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
