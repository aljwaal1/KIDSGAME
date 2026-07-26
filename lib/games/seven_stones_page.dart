import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class SevenStonesPage extends StatefulWidget {
  const SevenStonesPage({super.key});

  @override
  State<SevenStonesPage> createState() => _SevenStonesPageState();
}

class _SevenStonesPageState extends State<SevenStonesPage> with SingleTickerProviderStateMixin {
  late final AnimationController controller;
  int level = 0;
  int score = 0;
  int misses = 0;
  bool finished = false;
  bool busy = false;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1250))..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void reset() {
    setState(() {
      level = 0;
      misses = 0;
      finished = false;
      busy = false;
    });
    controller.repeat(reverse: true);
    SoundService.instance.play('click.wav');
  }

  Future<void> placeStone() async {
    if (finished || busy) return;
    setState(() => busy = true);
    final movingX = math.sin(controller.value * math.pi * 2) * .36;
    try {
      if (movingX.abs() < .12) {
        await SoundService.instance.play('pop.wav');
        if (!mounted) return;
        setState(() => level++);
        if (level >= 7) {
          setState(() {
            finished = true;
            score++;
          });
          controller.stop();
          await ScoreService.instance.addStars(3);
          await SoundService.instance.play('win.wav');
          if (mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('رائع! بنيت سبع حجارة')));
          }
        }
      } else {
        await SoundService.instance.play('wrong.wav');
        if (!mounted) return;
        setState(() {
          misses++;
          if (level > 0) level--;
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canPlace = !finished && !busy;
    return Scaffold(
      appBar: AppBar(title: const Text('سبع حجارة'), actions: <Widget>[IconButton(onPressed: reset, icon: const Icon(Icons.refresh_rounded))]),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          children: <Widget>[
            _SevenHeader(level: level, score: score, misses: misses),
            const SizedBox(height: 10),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: canPlace ? placeStone : null,
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) => CustomPaint(
                    painter: _SevenStonesPainter(level: level, movingValue: controller.value, finished: finished),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: finished
                  ? FilledButton.icon(onPressed: reset, icon: const Icon(Icons.replay_rounded), label: const Text('ابدأ برجًا جديدًا'))
                  : FilledButton.icon(onPressed: canPlace ? placeStone : null, icon: const Icon(Icons.touch_app_rounded), label: Text(busy ? 'انتظر...' : 'ضع الحجر عندما يكون في الوسط')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SevenHeader extends StatelessWidget {
  const _SevenHeader({required this.level, required this.score, required this.misses});
  final int level;
  final int score;
  final int misses;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 102,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors: <Color>[Color(0xFF78350F), Color(0xFFF97316)])),
      child: Row(children: <Widget>[
        const Icon(Icons.layers_rounded, color: Colors.white, size: 42),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text('ابنِ الحجارة: $level / 7', style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 21, fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text('النجاحات: $score  •  الأخطاء: $misses', style: const TextStyle(color: Color(0xFFFFF7D6), fontWeight: FontWeight.w700)),
        ])),
      ]),
    );
  }
}

class _SevenStonesPainter extends CustomPainter {
  const _SevenStonesPainter({required this.level, required this.movingValue, required this.finished});
  final int level;
  final double movingValue;
  final bool finished;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(28));
    canvas.drawRRect(bg, Paint()..color = const Color(0xFFFFF7ED));
    canvas.drawRRect(bg, Paint()..style = PaintingStyle.stroke..strokeWidth = 4..color = const Color(0xFFF59E0B));

    final centerX = size.width / 2;
    final baseY = size.height * .82;
    final stoneH = size.height * .072;
    final colors = <Color>[const Color(0xFF92400E), const Color(0xFFB45309), const Color(0xFFD97706), const Color(0xFFF59E0B), const Color(0xFFFBBF24), const Color(0xFFCA8A04), const Color(0xFF854D0E)];

    final guidePaint = Paint()..color = const Color(0x3322C55E);
    canvas.drawRect(Rect.fromCenter(center: Offset(centerX, size.height * .45), width: size.width * .26, height: size.height * .78), guidePaint);

    for (var i = 0; i < level; i++) {
      final width = size.width * (.48 - i * .035);
      final y = baseY - i * stoneH * 1.05;
      final rect = Rect.fromCenter(center: Offset(centerX, y), width: width, height: stoneH);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(22)), Paint()..color = colors[i % colors.length]);
      canvas.drawRRect(RRect.fromRectAndRadius(rect.translate(-4, -4), const Radius.circular(22)), Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.white.withAlpha(110));
    }

    if (!finished && level < 7) {
      final movingX = centerX + math.sin(movingValue * math.pi * 2) * size.width * .36;
      final movingY = size.height * .16;
      final width = size.width * (.48 - level * .035);
      final rect = Rect.fromCenter(center: Offset(movingX, movingY), width: width, height: stoneH);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(22)), Paint()..color = colors[level % colors.length]);
      canvas.drawLine(Offset(movingX, movingY + stoneH), Offset(centerX, baseY - level * stoneH * 1.05), Paint()..color = const Color(0x55EA580C)..strokeWidth = 3..strokeCap = StrokeCap.round);
    }

    if (finished) {
      final textPainter = TextPainter(text: const TextSpan(text: 'اكتملت!', style: TextStyle(color: Color(0xFF22C55E), fontSize: 34, fontWeight: FontWeight.w900)), textDirection: TextDirection.rtl)..layout();
      textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, size.height * .08));
    }
  }

  @override
  bool shouldRepaint(covariant _SevenStonesPainter oldDelegate) => oldDelegate.level != level || oldDelegate.movingValue != movingValue || oldDelegate.finished != finished;
}
