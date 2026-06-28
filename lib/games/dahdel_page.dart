import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class DahdelPage extends StatefulWidget {
  const DahdelPage({super.key});

  @override
  State<DahdelPage> createState() => _DahdelPageState();
}

class _DahdelPageState extends State<DahdelPage> {
  double aim = 0.5;
  double power = 0.55;
  double ballX = 0.5;
  double ballY = 0.88;
  int score = 0;
  int tries = 0;
  bool rolling = false;
  String message = 'اسحب لتحديد اتجاه الدحدل';

  void resetBall() {
    setState(() {
      ballX = 0.5;
      ballY = 0.88;
      rolling = false;
      message = 'اسحب لتحديد اتجاه الدحدل';
    });
  }

  Future<void> roll() async {
    if (rolling) return;
    setState(() {
      rolling = true;
      tries++;
      message = 'الدحدل يتحرك...';
    });
    await SoundService.instance.play('move.wav');

    final targetX = 0.5;
    final targetY = 0.16;
    final drift = (aim - 0.5) * 0.42;
    final finalX = (0.5 + drift).clamp(0.12, 0.88).toDouble();
    final finalY = (0.88 - power * 0.78).clamp(0.14, 0.88).toDouble();

    const frames = 18;
    final startX = ballX;
    final startY = ballY;
    for (var i = 1; i <= frames; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 22));
      if (!mounted) return;
      final t = i / frames;
      setState(() {
        ballX = startX + (finalX - startX) * t;
        ballY = startY + (finalY - startY) * t;
      });
    }

    final distance = math.sqrt(math.pow(ballX - targetX, 2) + math.pow(ballY - targetY, 2));
    if (distance < 0.13) {
      score++;
      await ScoreService.instance.addStars(2);
      await SoundService.instance.play('win.wav');
      if (!mounted) return;
      setState(() => message = 'رائع! دخل الدحدل في الهدف');
    } else {
      await SoundService.instance.play('wrong.wav');
      if (!mounted) return;
      setState(() => message = 'قريب! جرّب اتجاهًا أقرب للوسط');
    }
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (mounted) resetBall();
  }

  void updateAim(DragUpdateDetails details, double width) {
    if (rolling) return;
    setState(() {
      aim = (details.localPosition.dx / width).clamp(0.05, 0.95).toDouble();
      power = (1 - (details.localPosition.dy / 220)).clamp(0.30, 0.95).toDouble();
      message = 'اترك إصبعك لدحرجة الدحدل';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الدحدل')),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          children: <Widget>[
            _DahdelHeader(score: score, tries: tries, message: message),
            const SizedBox(height: 10),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onPanUpdate: (details) => updateAim(details, constraints.maxWidth),
                    onPanEnd: (_) => roll(),
                    onTap: roll,
                    child: CustomPaint(
                      painter: _DahdelPainter(aim: aim, power: power, ballX: ballX, ballY: ballY, rolling: rolling),
                      child: const SizedBox.expand(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            _HintBox(text: rolling ? 'انتظر حتى يتوقف الدحدل' : 'حرّك إصبعك يمينًا ويسارًا ثم اتركه.'),
          ],
        ),
      ),
    );
  }
}

class _DahdelHeader extends StatelessWidget {
  const _DahdelHeader({required this.score, required this.tries, required this.message});
  final int score;
  final int tries;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), gradient: const LinearGradient(colors: <Color>[Color(0xFF0F766E), Color(0xFF14B8A6)])),
      child: Row(children: <Widget>[
        const Icon(Icons.sports_baseball_rounded, color: Colors.white, size: 42),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text(message, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 19, fontWeight: FontWeight.w900)),
          const SizedBox(height: 5),
          Text('النقاط: $score  •  المحاولات: $tries', style: const TextStyle(color: Color(0xFFE0F2FE), fontWeight: FontWeight.w700)),
        ])),
      ]),
    );
  }
}

class _DahdelPainter extends CustomPainter {
  const _DahdelPainter({required this.aim, required this.power, required this.ballX, required this.ballY, required this.rolling});
  final double aim;
  final double power;
  final double ballX;
  final double ballY;
  final bool rolling;

  @override
  void paint(Canvas canvas, Size size) {
    final field = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(28));
    canvas.drawRRect(field, Paint()..color = const Color(0xFFECFDF5));
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..color = const Color(0xFF0F766E);
    canvas.drawRRect(field, border);

    final lanePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = const Color(0x55888888);
    for (var x = .2; x <= .8; x += .2) {
      canvas.drawLine(Offset(size.width * x, 16), Offset(size.width * x, size.height - 16), lanePaint);
    }

    final target = Offset(size.width * .5, size.height * .16);
    canvas.drawCircle(target, 42, Paint()..color = const Color(0xFFFFFFFF));
    canvas.drawCircle(target, 42, Paint()..style = PaintingStyle.stroke..strokeWidth = 5..color = const Color(0xFF22C55E));
    canvas.drawCircle(target, 17, Paint()..color = const Color(0xFF22C55E));

    final start = Offset(size.width * .5, size.height * .88);
    final aimPoint = Offset(size.width * aim, size.height * (.88 - power * .42));
    final aimPaint = Paint()
      ..color = const Color(0xFFEA580C)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    if (!rolling) canvas.drawLine(start, aimPoint, aimPaint);

    final ball = Offset(size.width * ballX, size.height * ballY);
    canvas.drawCircle(ball.translate(4, 7), 23, Paint()..color = const Color(0x33000000));
    canvas.drawCircle(ball, 24, Paint()..color = const Color(0xFF92400E));
    canvas.drawCircle(ball.translate(-7, -7), 8, Paint()..color = const Color(0xFFFFF7ED));
  }

  @override
  bool shouldRepaint(covariant _DahdelPainter oldDelegate) {
    return oldDelegate.aim != aim || oldDelegate.power != power || oldDelegate.ballX != ballX || oldDelegate.ballY != ballY || oldDelegate.rolling != rolling;
  }
}

class _HintBox extends StatelessWidget {
  const _HintBox({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(height: 52, alignment: Alignment.center, decoration: BoxDecoration(color: const Color(0xFFF0FDFA), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFF99F6E4))), child: Text(text, style: const TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w800)));
  }
}
