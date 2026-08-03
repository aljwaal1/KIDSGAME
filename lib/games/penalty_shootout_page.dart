import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/sound_service.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/game_header.dart';

class PenaltyShootoutPage extends StatefulWidget {
  const PenaltyShootoutPage({super.key});

  @override
  State<PenaltyShootoutPage> createState() => _PenaltyShootoutPageState();
}

class _PenaltyShootoutPageState extends State<PenaltyShootoutPage>
    with SingleTickerProviderStateMixin {
  final math.Random _random = math.Random();
  final GlobalKey<ConfettiOverlayState> _confettiKey =
      GlobalKey<ConfettiOverlayState>();
  late final AnimationController _kickAnimation;

  bool _againstBot = true;
  bool _playerOneShoots = true;
  bool _animating = false;
  bool _finished = false;
  bool _handoffCover = false;
  int _playerOneGoals = 0;
  int _playerTwoGoals = 0;
  int _playerOneKicks = 0;
  int _playerTwoKicks = 0;
  int? _shotZone;
  int? _keeperZone;
  int? _secretShot;
  String? _resultText;

  @override
  void initState() {
    super.initState();
    _kickAnimation = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 720),
    )..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _kickAnimation.dispose();
    super.dispose();
  }

  void _reset() {
    _kickAnimation.reset();
    setState(() {
      _playerOneShoots = true;
      _animating = false;
      _finished = false;
      _handoffCover = false;
      _playerOneGoals = 0;
      _playerTwoGoals = 0;
      _playerOneKicks = 0;
      _playerTwoKicks = 0;
      _shotZone = null;
      _keeperZone = null;
      _secretShot = null;
      _resultText = null;
    });
  }

  void _changeMode(bool againstBot) {
    _againstBot = againstBot;
    _reset();
  }

  int _zoneFromTap(Offset point, Size size) {
    final relativeX = (point.dx / size.width).clamp(0.0, 0.999);
    return (relativeX * 3).floor();
  }

  void _tapPitch(Offset point, Size size) {
    if (_finished || _animating || _handoffCover) return;
    final zone = _zoneFromTap(point, size);

    if (_againstBot) {
      if (_playerOneShoots) {
        _resolveKick(zone, _random.nextInt(3), true);
      } else {
        _resolveKick(_random.nextInt(3), zone, false);
      }
      return;
    }

    if (_secretShot == null) {
      setState(() {
        _secretShot = zone;
        _handoffCover = true;
      });
    } else {
      final shot = _secretShot!;
      _secretShot = null;
      _resolveKick(shot, zone, _playerOneShoots);
    }
  }

  Future<void> _resolveKick(int shot, int keeper, bool playerOneShot) async {
    final goal = shot != keeper;
    setState(() {
      _shotZone = shot;
      _keeperZone = keeper;
      _animating = true;
      _resultText = null;
      if (playerOneShot) {
        _playerOneKicks++;
        if (goal) _playerOneGoals++;
      } else {
        _playerTwoKicks++;
        if (goal) _playerTwoGoals++;
      }
    });

    await _kickAnimation.forward(from: 0);
    if (!mounted) return;
    setState(() => _resultText = goal ? 'هــدف!' : 'تصدٍ رائع!');
    SoundService.instance.play(goal ? 'chime.wav' : 'wrong.wav');
    await Future<void>.delayed(const Duration(milliseconds: 850));
    if (!mounted) return;

    final roundComplete = _playerOneKicks >= 5 &&
        _playerOneKicks == _playerTwoKicks &&
        _playerOneGoals != _playerTwoGoals;
    setState(() {
      _animating = false;
      _shotZone = null;
      _keeperZone = null;
      _resultText = null;
      if (roundComplete) {
        _finished = true;
      } else {
        _playerOneShoots = !_playerOneShoots;
      }
    });
    _kickAnimation.reset();

    if (roundComplete) {
      _confettiKey.currentState?.burst();
      SoundService.instance.play('win.wav');
    }
  }

  String get _instruction {
    if (_finished) {
      final winner = _playerOneGoals > _playerTwoGoals
          ? 'أنت الفائز! 🏆'
          : '${_againstBot ? 'الروبوت' : 'اللاعب 2'} فاز';
      return '$winner  •  $_playerOneGoals - $_playerTwoGoals';
    }
    if (_handoffCover) return 'سلّم الهاتف إلى حارس المرمى';
    if (!_againstBot && _secretShot != null) {
      return 'الحارس: اضغط داخل المرمى للقفز';
    }
    if (_playerOneShoots) return 'اضغط داخل المرمى لتسديد الكرة';
    return 'أنت الحارس — اضغط جهة القفز';
  }

  @override
  Widget build(BuildContext context) {
    return ConfettiOverlay(
      key: _confettiKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          children: <Widget>[
            GameHeader(
              title: 'ركلات الترجيح',
              subtitle: _instruction,
              color: const Color(0xFF087F5B),
              onReset: _reset,
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: _ModeButton(
                    label: 'ضد الروبوت',
                    icon: Icons.smart_toy_rounded,
                    selected: _againstBot,
                    onTap: () => _changeMode(true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ModeButton(
                    label: 'مع صديق',
                    icon: Icons.people_alt_rounded,
                    selected: !_againstBot,
                    onTap: () => _changeMode(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ScoreBoard(
              playerOneGoals: _playerOneGoals,
              playerTwoGoals: _playerTwoGoals,
              playerOneKicks: _playerOneKicks,
              playerTwoKicks: _playerTwoKicks,
              opponentName: _againstBot ? 'الروبوت' : 'اللاعب 2',
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) =>
                          _tapPitch(details.localPosition, size),
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          CustomPaint(
                            painter: _PenaltyPitchPainter(
                              shotZone: _shotZone,
                              keeperZone: _keeperZone,
                              progress: Curves.easeInOutCubic.transform(
                                _kickAnimation.value,
                              ),
                              showTargets: !_animating && !_handoffCover,
                            ),
                          ),
                          if (_resultText != null)
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: _resultText!.startsWith('ه')
                                      ? const Color(0xFFEAB308)
                                      : const Color(0xFF2563EB),
                                  borderRadius: BorderRadius.circular(99),
                                  boxShadow: const <BoxShadow>[
                                    BoxShadow(
                                      color: Color(0x66000000),
                                      blurRadius: 18,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  _resultText!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                    fontFamily: 'Changa',
                                  ),
                                ),
                              ),
                            ),
                          if (_handoffCover) _buildHandoffCover(),
                        ],
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

  Widget _buildHandoffCover() {
    return ColoredBox(
      color: const Color(0xF014533D),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.phonelink_lock_rounded, color: Colors.white, size: 54),
          const SizedBox(height: 12),
          const Text(
            'لا تكشف جهة التسديدة!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontFamily: 'Changa',
            ),
          ),
          const Text(
            'سلّم الهاتف إلى حارس المرمى',
            style: TextStyle(color: Color(0xFFD1FAE5), fontSize: 15),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => setState(() => _handoffCover = false),
            icon: const Icon(Icons.sports_soccer_rounded),
            label: const Text('الحارس جاهز'),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF087F5B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF087F5B) : const Color(0xFFD1D5DB),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 20, color: selected ? Colors.white : const Color(0xFF374151)),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF374151),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBoard extends StatelessWidget {
  const _ScoreBoard({
    required this.playerOneGoals,
    required this.playerTwoGoals,
    required this.playerOneKicks,
    required this.playerTwoKicks,
    required this.opponentName,
  });

  final int playerOneGoals;
  final int playerTwoGoals;
  final int playerOneKicks;
  final int playerTwoKicks;
  final String opponentName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: _team('أنت', playerOneGoals, playerOneKicks, const Color(0xFF34D399))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF030712),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$playerOneGoals  -  $playerTwoGoals',
              style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(child: _team(opponentName, playerTwoGoals, playerTwoKicks, const Color(0xFFF87171))),
        ],
      ),
    );
  }

  Widget _team(String name, int goals, int kicks, Color color) {
    return Column(
      children: <Widget>[
        Text(name, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(5, (index) {
            final taken = index < kicks;
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: taken ? color : const Color(0xFF4B5563),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PenaltyPitchPainter extends CustomPainter {
  const _PenaltyPitchPainter({
    required this.shotZone,
    required this.keeperZone,
    required this.progress,
    required this.showTargets,
  });

  final int? shotZone;
  final int? keeperZone;
  final double progress;
  final bool showTargets;

  @override
  void paint(Canvas canvas, Size size) {
    final stadiumHeight = size.height * 0.25;
    final crowd = Rect.fromLTWH(0, 0, size.width, stadiumHeight);
    canvas.drawRect(
      crowd,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFF0F172A), Color(0xFF334155)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(crowd),
    );
    _drawCrowd(canvas, crowd, size);

    final field = Rect.fromLTWH(0, stadiumHeight, size.width, size.height - stadiumHeight);
    canvas.drawRect(field, Paint()..color = const Color(0xFF159447));
    for (var i = 0; i < 7; i++) {
      final stripe = Rect.fromLTWH(
        i * size.width / 7,
        stadiumHeight,
        size.width / 7,
        field.height,
      );
      canvas.drawRect(
        stripe,
        Paint()..color = i.isEven ? const Color(0x1814532D) : const Color(0x10000000),
      );
    }

    final goal = Rect.fromLTWH(
      size.width * 0.09,
      size.height * 0.22,
      size.width * 0.82,
      size.height * 0.42,
    );
    _drawGoal(canvas, goal, size);
    _drawPenaltyArea(canvas, size, goal);

    if (showTargets) _drawTargets(canvas, goal);

    final keeperStart = Offset(goal.center.dx, goal.bottom - size.height * 0.07);
    final keeperEnd = Offset(
      goal.left + goal.width * (((keeperZone ?? 1) + 0.5) / 3),
      goal.top + goal.height * 0.60,
    );
    final keeperPosition = keeperZone == null
        ? keeperStart
        : Offset.lerp(keeperStart, keeperEnd, progress)!;
    _drawKeeper(canvas, keeperPosition, size, keeperZone, progress);

    final ballStart = Offset(size.width * 0.5, size.height * 0.88);
    final ballEnd = Offset(
      goal.left + goal.width * (((shotZone ?? 1) + 0.5) / 3),
      goal.top + goal.height * 0.55,
    );
    final ballPosition = shotZone == null
        ? ballStart
        : Offset.lerp(ballStart, ballEnd, progress)!;
    final ballRadius = size.width * (0.052 - progress * 0.018);
    _drawBall(canvas, ballPosition, ballRadius);
  }

  void _drawCrowd(Canvas canvas, Rect crowd, Size size) {
    final colors = <Color>[
      const Color(0xFFFBBF24),
      const Color(0xFF60A5FA),
      const Color(0xFFF87171),
      const Color(0xFFF8FAFC),
    ];
    for (var row = 0; row < 4; row++) {
      for (var column = 0; column < 18; column++) {
        final color = colors[(row * 5 + column * 3) % colors.length];
        canvas.drawCircle(
          Offset(
            (column + 0.5) * size.width / 18,
            crowd.top + 12 + row * crowd.height / 5,
          ),
          2.3,
          Paint()..color = color.withAlpha(190),
        );
      }
    }
  }

  void _drawGoal(Canvas canvas, Rect goal, Size size) {
    final netPaint = Paint()
      ..color = const Color(0xAAE2E8F0)
      ..strokeWidth = 1.2;
    for (var i = 1; i < 9; i++) {
      final x = goal.left + goal.width * i / 9;
      canvas.drawLine(Offset(x, goal.top), Offset(x, goal.bottom), netPaint);
    }
    for (var i = 1; i < 6; i++) {
      final y = goal.top + goal.height * i / 6;
      canvas.drawLine(Offset(goal.left, y), Offset(goal.right, y), netPaint);
    }
    final posts = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(5.0, size.width * 0.018)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final frame = Path()
      ..moveTo(goal.left, goal.bottom)
      ..lineTo(goal.left, goal.top)
      ..lineTo(goal.right, goal.top)
      ..lineTo(goal.right, goal.bottom);
    canvas.drawPath(frame, posts);
  }

  void _drawPenaltyArea(Canvas canvas, Size size, Rect goal) {
    final line = Paint()
      ..color = const Color(0xCCFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    final area = Path()
      ..moveTo(goal.left - size.width * 0.07, goal.bottom)
      ..lineTo(size.width * 0.03, size.height)
      ..moveTo(goal.right + size.width * 0.07, goal.bottom)
      ..lineTo(size.width * 0.97, size.height);
    canvas.drawPath(area, line);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.88), 3.5, Paint()..color = Colors.white);
  }

  void _drawTargets(Canvas canvas, Rect goal) {
    for (var zone = 0; zone < 3; zone++) {
      final center = Offset(
        goal.left + goal.width * (zone + 0.5) / 3,
        goal.top + goal.height * 0.48,
      );
      canvas.drawCircle(
        center,
        goal.width * 0.095,
        Paint()
          ..color = const Color(0x26FFFFFF)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        center,
        goal.width * 0.095,
        Paint()
          ..color = const Color(0xAAFFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  void _drawKeeper(Canvas canvas, Offset center, Size size, int? zone, double t) {
    final diving = zone != null && t > 0.12;
    final direction = (zone ?? 1) - 1;
    final tilt = diving ? direction * 0.55 : 0.0;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(tilt);
    final scale = size.width / 390;
    canvas.drawCircle(Offset(0, -28 * scale), 11 * scale, Paint()..color = const Color(0xFFD8A06A));
    final shirt = Paint()..color = const Color(0xFFF97316);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 30 * scale, height: 42 * scale),
        Radius.circular(8 * scale),
      ),
      shirt,
    );
    final limb = Paint()
      ..color = const Color(0xFFF97316)
      ..strokeWidth = 8 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-12 * scale, -8 * scale), Offset(-34 * scale, -23 * scale), limb);
    canvas.drawLine(Offset(12 * scale, -8 * scale), Offset(34 * scale, -23 * scale), limb);
    final gloves = Paint()..color = const Color(0xFFA7F3D0);
    canvas.drawCircle(Offset(-38 * scale, -26 * scale), 7 * scale, gloves);
    canvas.drawCircle(Offset(38 * scale, -26 * scale), 7 * scale, gloves);
    final shorts = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..strokeWidth = 10 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(-7 * scale, 18 * scale), Offset(-14 * scale, 42 * scale), shorts);
    canvas.drawLine(Offset(7 * scale, 18 * scale), Offset(14 * scale, 42 * scale), shorts);
    canvas.restore();
  }

  void _drawBall(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(
      center + Offset(radius * 0.16, radius * 0.22),
      radius * 1.12,
      Paint()..color = const Color(0x44000000),
    );
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF111827)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, radius * 0.1),
    );
    final panel = Path();
    for (var i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + i * math.pi * 2 / 5;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.38;
      if (i == 0) {
        panel.moveTo(point.dx, point.dy);
      } else {
        panel.lineTo(point.dx, point.dy);
      }
    }
    panel.close();
    canvas.drawPath(panel, Paint()..color = const Color(0xFF111827));
    for (var i = 0; i < 5; i++) {
      final angle = -math.pi / 2 + i * math.pi * 2 / 5;
      canvas.drawLine(
        center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.38,
        center + Offset(math.cos(angle), math.sin(angle)) * radius * 0.86,
        Paint()
          ..color = const Color(0xFF374151)
          ..strokeWidth = math.max(1.0, radius * 0.07),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PenaltyPitchPainter oldDelegate) {
    return oldDelegate.shotZone != shotZone ||
        oldDelegate.keeperZone != keeperZone ||
        oldDelegate.progress != progress ||
        oldDelegate.showTargets != showTargets;
  }
}
