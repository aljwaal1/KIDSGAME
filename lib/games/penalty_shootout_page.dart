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
    final media = MediaQuery.of(context);
    return MediaQuery(
      // Large system fonts must not break the scoreboard or shrink the pitch.
      // This game uses large, high-contrast controls of its own.
      data: media.copyWith(textScaler: const TextScaler.linear(1.0)),
      child: ConfettiOverlay(
        key: _confettiKey,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          child: Column(
            children: <Widget>[
            GameHeader(
              title: 'ركلات الترجيح',
              subtitle: _instruction,
              color: const Color(0xFF087F5B),
              onReset: _reset,
            ),
            const SizedBox(height: 6),
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
            const SizedBox(height: 6),
            _ScoreBoard(
              playerOneGoals: _playerOneGoals,
              playerTwoGoals: _playerTwoGoals,
              playerOneKicks: _playerOneKicks,
              playerTwoKicks: _playerTwoKicks,
              opponentName: _againstBot ? 'الروبوت' : 'اللاعب 2',
            ),
            const SizedBox(height: 6),
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
                          Image.asset(
                            'assets/images/puzzle/penalty_stadium_v2.png',
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            filterQuality: FilterQuality.high,
                          ),
                          _GoalkeeperSprite(
                            size: size,
                            zone: _keeperZone,
                            progress: Curves.easeInOutCubic.transform(
                              _kickAnimation.value,
                            ),
                          ),
                          CustomPaint(
                            painter: _PenaltyPitchPainter(
                              showTargets: !_animating && !_handoffCover,
                            ),
                          ),
                          _BallSprite(
                            size: size,
                            zone: _shotZone,
                            progress: Curves.easeInOutCubic.transform(
                              _kickAnimation.value,
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
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
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
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: _team('أنت', playerOneKicks, const Color(0xFF34D399))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF030712),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$playerOneGoals  :  $playerTwoGoals',
              maxLines: 1,
              style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900),
            ),
          ),
          Expanded(child: _team(opponentName, playerTwoKicks, const Color(0xFFF87171))),
        ],
      ),
    );
  }

  Widget _team(String name, int kicks, Color color) {
    return Column(
      children: <Widget>[
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900)),
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

class _GoalkeeperSprite extends StatelessWidget {
  const _GoalkeeperSprite({
    required this.size,
    required this.zone,
    required this.progress,
  });

  final Size size;
  final int? zone;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final targetX = zone == null ? .5 : (.25 + zone! * .25);
    final x = .5 + (targetX - .5) * progress;
    final y = .48 - .08 * progress;
    final width = size.width * .31;
    final height = size.height * .37;
    final direction = (zone ?? 1) - 1;
    return Positioned(
      left: x * size.width - width / 2,
      top: y * size.height - height / 2,
      width: width,
      height: height,
      child: Transform.rotate(
        angle: direction * .48 * progress,
        child: Image.asset(
          'assets/images/puzzle/penalty_keeper_v2.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _BallSprite extends StatelessWidget {
  const _BallSprite({
    required this.size,
    required this.zone,
    required this.progress,
  });

  final Size size;
  final int? zone;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final start = Offset(size.width * .5, size.height * .84);
    final target = Offset(
      size.width * (.10 + .80 * (((zone ?? 1) + .5) / 3)),
      size.height * .424,
    );
    final position = zone == null ? start : Offset.lerp(start, target, progress)!;
    final diameter = size.width * (.115 - .045 * progress);
    return Positioned(
      left: position.dx - diameter / 2,
      top: position.dy - diameter / 2,
      width: diameter,
      height: diameter,
      child: Transform.rotate(
        angle: progress * math.pi * 4,
        child: Image.asset(
          'assets/images/puzzle/penalty_ball_v2.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}

class _PenaltyPitchPainter extends CustomPainter {
  const _PenaltyPitchPainter({required this.showTargets});

  final bool showTargets;

  @override
  void paint(Canvas canvas, Size size) {
    final goal = Rect.fromLTWH(
      size.width * 0.10,
      size.height * 0.27,
      size.width * 0.80,
      size.height * 0.28,
    );

    if (showTargets) _drawTargets(canvas, goal);

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

  @override
  bool shouldRepaint(covariant _PenaltyPitchPainter oldDelegate) {
    return oldDelegate.showTargets != showTargets;
  }
}
