import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/sound_service.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/game_header.dart';

class BattleshipPage extends StatefulWidget {
  const BattleshipPage({super.key});

  @override
  State<BattleshipPage> createState() => _BattleshipPageState();
}

class _BattleshipPageState extends State<BattleshipPage> {
  static const int boardSize = 8;
  static const List<int> shipLengths = <int>[4, 3, 3, 2];

  final Random _random = Random();
  final GlobalKey<ConfettiOverlayState> _confettiKey =
      GlobalKey<ConfettiOverlayState>();
  Timer? _botTimer;

  bool _againstBot = true;
  bool _placing = true;
  bool _horizontal = true;
  bool _covered = false;
  int _placingPlayer = 0;
  int _placingShip = 0;
  int _player = 0;
  int? _winner;
  String? _placementError;
  late List<List<Set<int>>> _fleets;
  late List<Set<int>> _shots;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _botTimer?.cancel();
    super.dispose();
  }

  void _reset() {
    _botTimer?.cancel();
    _fleets = <List<Set<int>>>[<Set<int>>[], <Set<int>>[]];
    _shots = <Set<int>>[<int>{}, <int>{}];
    setState(() {
      _placing = true;
      _horizontal = true;
      _covered = false;
      _placingPlayer = 0;
      _placingShip = 0;
      _player = 0;
      _winner = null;
      _placementError = null;
    });
  }

  void _setMode(bool againstBot) {
    if (_againstBot == againstBot) return;
    _againstBot = againstBot;
    SoundService.instance.play('click.wav');
    _reset();
  }

  List<Set<int>> _randomFleet() {
    final ships = <Set<int>>[];
    for (final length in shipLengths) {
      while (true) {
        final horizontal = _random.nextBool();
        final row = _random.nextInt(horizontal ? boardSize : boardSize - length + 1);
        final column = _random.nextInt(horizontal ? boardSize - length + 1 : boardSize);
        final ship = <int>{
          for (var part = 0; part < length; part++)
            (row + (horizontal ? 0 : part)) * boardSize +
                column +
                (horizontal ? part : 0),
        };
        if (ships.every((existing) => existing.intersection(ship).isEmpty)) {
          ships.add(ship);
          break;
        }
      }
    }
    return ships;
  }

  void _placeShip(int cell) {
    if (!_placing || _covered || _placingShip >= shipLengths.length) return;
    final row = cell ~/ boardSize;
    final column = cell % boardSize;
    final length = shipLengths[_placingShip];
    if ((_horizontal && column + length > boardSize) ||
        (!_horizontal && row + length > boardSize)) {
      _showPlacementError('السفينة ستخرج خارج حدود البحر');
      return;
    }
    final ship = <int>{
      for (var part = 0; part < length; part++)
        (row + (_horizontal ? 0 : part)) * boardSize +
            column +
            (_horizontal ? part : 0),
    };
    if (_fleets[_placingPlayer]
        .any((existing) => existing.intersection(ship).isNotEmpty)) {
      _showPlacementError('لا يمكن وضع سفينتين فوق بعضهما');
      return;
    }
    setState(() {
      _fleets[_placingPlayer].add(ship);
      _placingShip++;
      _placementError = null;
    });
    HapticFeedback.lightImpact();
    SoundService.instance.play('move.wav');
  }

  void _showPlacementError(String text) {
    setState(() => _placementError = text);
    HapticFeedback.selectionClick();
    SoundService.instance.play('wrong.wav');
  }

  void _undoShip() {
    if (_placingShip == 0 || _covered) return;
    setState(() {
      _fleets[_placingPlayer].removeLast();
      _placingShip--;
      _placementError = null;
    });
    SoundService.instance.play('click.wav');
  }

  void _shuffleFleet() {
    if (_covered) return;
    setState(() {
      _fleets[_placingPlayer] = _randomFleet();
      _placingShip = shipLengths.length;
      _placementError = null;
    });
    SoundService.instance.play('chime.wav');
  }

  void _confirmFleet() {
    if (_placingShip < shipLengths.length || _covered) return;
    SoundService.instance.play('chime.wav');
    if (_againstBot) {
      _fleets[1] = _randomFleet();
      setState(() {
        _placing = false;
        _player = 0;
      });
      return;
    }
    if (_placingPlayer == 0) {
      setState(() {
        _placingPlayer = 1;
        _placingShip = 0;
        _horizontal = true;
        _covered = true;
        _placementError = null;
      });
    } else {
      setState(() {
        _placing = false;
        _player = 0;
        _covered = true;
      });
    }
  }

  bool _hasShip(int owner, int cell) {
    return _fleets[owner].any((ship) => ship.contains(cell));
  }

  bool _shipSunk(int owner, Set<int> ship) {
    return ship.every(_shots[1 - owner].contains);
  }

  int _remainingShips(int owner) {
    return _fleets[owner].where((ship) => !_shipSunk(owner, ship)).length;
  }

  void _fire(int cell, {bool robot = false}) {
    if (_placing ||
        _winner != null ||
        _covered ||
        (_againstBot && _player == 1 && !robot) ||
        _shots[_player].contains(cell)) {
      return;
    }
    final hit = _hasShip(1 - _player, cell);
    final shooter = _player;
    setState(() => _shots[shooter].add(cell));
    HapticFeedback.mediumImpact();
    SoundService.instance.play(hit ? 'pop.wav' : 'tap.wav');

    if (_fleets[1 - shooter]
        .every((ship) => ship.every(_shots[shooter].contains))) {
      setState(() => _winner = shooter);
      _confettiKey.currentState?.burst(count: 38);
      SoundService.instance.play('win.wav');
      return;
    }

    setState(() {
      _player = 1 - shooter;
      _covered = !_againstBot;
    });
    if (_againstBot && _player == 1) _scheduleBot();
  }

  void _scheduleBot() {
    _botTimer?.cancel();
    _botTimer = Timer(const Duration(milliseconds: 950), () {
      if (!mounted || _winner != null || _player != 1) return;
      final available = <int>[
        for (var cell = 0; cell < boardSize * boardSize; cell++)
          if (!_shots[1].contains(cell)) cell,
      ];
      final closeTargets = available.where((cell) {
        return _neighbors(cell).any(
          (neighbor) =>
              _shots[1].contains(neighbor) && _hasShip(0, neighbor),
        );
      }).toList();
      final pool = closeTargets.isNotEmpty ? closeTargets : available;
      _fire(pool[_random.nextInt(pool.length)], robot: true);
    });
  }

  Iterable<int> _neighbors(int cell) sync* {
    final row = cell ~/ boardSize;
    final column = cell % boardSize;
    if (row > 0) yield cell - boardSize;
    if (row < boardSize - 1) yield cell + boardSize;
    if (column > 0) yield cell - 1;
    if (column < boardSize - 1) yield cell + 1;
  }

  String get _subtitle {
    if (_placing) return 'المرحلة 1 من 2: رتّب أسطولك';
    if (_winner != null) {
      return 'فاز ${_againstBot && _winner == 1 ? 'الروبوت' : 'اللاعب ${_winner! + 1}'} بالمعركة!';
    }
    if (_covered) return 'سلّم الجهاز إلى اللاعب ${_player + 1}';
    if (_againstBot && _player == 1) return 'الروبوت يختار هدفه…';
    return 'المرحلة 2 من 2: اختر هدفاً في بحر الخصم';
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return MediaQuery(
      data: media.copyWith(textScaler: const TextScaler.linear(1.0)),
      child: ConfettiOverlay(
        key: _confettiKey,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Column(
            children: <Widget>[
              GameHeader(
                title: 'معركة السفن',
                subtitle: _subtitle,
                color: const Color(0xFF0369A1),
                onReset: _reset,
              ),
              const SizedBox(height: 7),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _ModeButton(
                      label: 'ضد الروبوت',
                      icon: Icons.smart_toy_rounded,
                      selected: _againstBot,
                      onTap: () => _setMode(true),
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: _ModeButton(
                      label: 'مع صديق',
                      icon: Icons.people_alt_rounded,
                      selected: !_againstBot,
                      onTap: () => _setMode(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Expanded(
                child: Stack(
                  children: <Widget>[
                    if (_placing) _buildPlacement() else _buildBattle(),
                    if (_covered) _buildPrivacyCover(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlacement() {
    final allPlaced = _placingShip == shipLengths.length;
    return Column(
      children: <Widget>[
        _StageBanner(
          icon: Icons.directions_boat_rounded,
          title: 'أسطول اللاعب ${_placingPlayer + 1}',
          text: allPlaced
              ? 'الأسطول جاهز — اضغط بدء المعركة'
              : 'ضع السفينة ${_placingShip + 1} بطول ${shipLengths[_placingShip]} خانات',
          color: const Color(0xFF0284C7),
        ),
        const SizedBox(height: 7),
        _ShipProgress(current: _placingShip, lengths: shipLengths),
        if (_placementError != null) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            _placementError!,
            style: const TextStyle(
              color: Color(0xFFDC2626),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Expanded(
          child: Center(
            child: _BattleGrid(
              owner: _placingPlayer,
              shots: const <int>{},
              fleets: _fleets,
              revealShips: true,
              onTap: _placeShip,
            ),
          ),
        ),
        const SizedBox(height: 7),
        Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: allPlaced
                    ? null
                    : () => setState(() => _horizontal = !_horizontal),
                icon: Icon(
                  _horizontal
                      ? Icons.swap_horiz_rounded
                      : Icons.swap_vert_rounded,
                ),
                label: Text(_horizontal ? 'أفقي' : 'عمودي'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _placingShip > 0 ? _undoShip : null,
                icon: const Icon(Icons.undo_rounded),
                label: const Text('تراجع'),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _shuffleFleet,
                icon: const Icon(Icons.shuffle_rounded),
                label: const Text('تلقائي'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: allPlaced ? _confirmFleet : null,
            icon: const Icon(Icons.check_circle_rounded),
            label: Text(
              _againstBot || _placingPlayer == 1
                  ? 'ابدأ المعركة'
                  : 'تأكيد أسطول اللاعب 1',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBattle() {
    final targetOwner = 1 - _player;
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: _FleetStatus(
                label: _againstBot && _player == 1
                    ? 'الروبوت يهاجم'
                    : 'اللاعب ${_player + 1} يهاجم',
                remaining: _remainingShips(targetOwner),
                color: const Color(0xFFF97316),
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: _FleetStatus(
                label: 'سفنك الباقية',
                remaining: _remainingShips(_player),
                color: const Color(0xFF0284C7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        const _StageBanner(
          icon: Icons.gps_fixed_rounded,
          title: 'بحر الخصم',
          text: 'اضغط خانة لإطلاق النار عليها',
          color: Color(0xFFEA580C),
        ),
        const SizedBox(height: 7),
        Expanded(
          child: Center(
            child: _BattleGrid(
              owner: targetOwner,
              shots: _shots[_player],
              fleets: _fleets,
              revealShips: false,
              onTap: _fire,
            ),
          ),
        ),
        const SizedBox(height: 7),
        const _Legend(),
      ],
    );
  }

  Widget _buildPrivacyCover() {
    final text = _placing
        ? 'سلّم الجهاز إلى اللاعب ${_placingPlayer + 1}\nليضع أسطوله بسرّية'
        : 'سلّم الجهاز إلى اللاعب ${_player + 1}\nحان وقت الهجوم';
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFA082F49), Color(0xFA0C4A6E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.visibility_off_rounded, color: Colors.white, size: 60),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                fontFamily: 'Changa',
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => setState(() => _covered = false),
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('أنا جاهز'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BattleGrid extends StatelessWidget {
  const _BattleGrid({
    required this.owner,
    required this.shots,
    required this.fleets,
    required this.revealShips,
    required this.onTap,
  });

  final int owner;
  final Set<int> shots;
  final List<List<Set<int>>> fleets;
  final bool revealShips;
  final ValueChanged<int>? onTap;

  Set<int>? _shipFor(int cell) {
    for (final ship in fleets[owner]) {
      if (ship.contains(cell)) return ship;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xFF075985),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF38BDF8), width: 3),
          boxShadow: const <BoxShadow>[
            BoxShadow(color: Color(0x440369A1), blurRadius: 14, offset: Offset(0, 7)),
          ],
        ),
        child: GridView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 8,
          ),
          itemCount: 64,
          itemBuilder: (context, cell) {
            final ship = _shipFor(cell);
            final hasShip = ship != null;
            final fired = shots.contains(cell);
            final hit = fired && hasShip;
            final sunk = hasShip && ship.every(shots.contains);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap == null ? null : () => onTap!(cell),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(1.2),
                decoration: BoxDecoration(
                  color: revealShips && hasShip
                      ? const Color(0xFF334155)
                      : const Color(0xFF0EA5E9),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xAA7DD3FC)),
                  boxShadow: revealShips && hasShip
                      ? const <BoxShadow>[
                          BoxShadow(color: Color(0x66000000), blurRadius: 3, offset: Offset(0, 2)),
                        ]
                      : null,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    if (revealShips && hasShip)
                      Icon(
                        Icons.directions_boat_rounded,
                        color: sunk ? const Color(0xFFFCA5A5) : Colors.white,
                        size: 18,
                      ),
                    if (fired && !hit)
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(color: Color(0x66000000), blurRadius: 3),
                          ],
                        ),
                      ),
                    if (hit)
                      const Icon(
                        Icons.close_rounded,
                        color: Color(0xFFFF3B30),
                        size: 31,
                        shadows: <Shadow>[
                          Shadow(color: Colors.white, blurRadius: 5),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
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
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 42,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0369A1) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF0369A1) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 19, color: selected ? Colors.white : const Color(0xFF475569)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF475569),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageBanner extends StatelessWidget {
  const _StageBanner({
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });
  final IconData icon;
  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: color, size: 29),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
                Text(text, style: const TextStyle(color: Color(0xFF475569), fontSize: 12, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShipProgress extends StatelessWidget {
  const _ShipProgress({required this.current, required this.lengths});
  final int current;
  final List<int> lengths;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (var index = 0; index < lengths.length; index++) ...<Widget>[
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              height: 31,
              decoration: BoxDecoration(
                color: index < current
                    ? const Color(0xFF16A34A)
                    : index == current
                        ? const Color(0xFF0284C7)
                        : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    index < current ? Icons.check_rounded : Icons.directions_boat_rounded,
                    color: index <= current ? Colors.white : const Color(0xFF64748B),
                    size: 16,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${lengths[index]}',
                    style: TextStyle(
                      color: index <= current ? Colors.white : const Color(0xFF64748B),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (index < lengths.length - 1) const SizedBox(width: 4),
        ],
      ],
    );
  }
}

class _FleetStatus extends StatelessWidget {
  const _FleetStatus({required this.label, required this.remaining, required this.color});
  final String label;
  final int remaining;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.directions_boat_rounded, color: color, size: 20),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              '$label: $remaining',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(13),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          _LegendItem(icon: Icons.circle, color: Colors.white, text: 'أخطأت'),
          _LegendItem(icon: Icons.close_rounded, color: Color(0xFFFF3B30), text: 'أصبت'),
          _LegendItem(icon: Icons.directions_boat_rounded, color: Color(0xFF334155), text: 'سفينة'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: color, size: 17),
        const SizedBox(width: 3),
        Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
