import 'dart:math';
import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

enum _MemoryLevel { easy, medium, hard, expert }

class MemoryPairsPage extends StatefulWidget {
  const MemoryPairsPage({super.key});
  @override
  State<MemoryPairsPage> createState() => _MemoryPairsPageState();
}

class _MemoryPairsPageState extends State<MemoryPairsPage> {
  final Random _random = Random();
  final List<IconData> icons = const <IconData>[
    Icons.star_rounded,
    Icons.favorite_rounded,
    Icons.pets_rounded,
    Icons.local_florist_rounded,
    Icons.cake_rounded,
    Icons.emoji_emotions_rounded,
    Icons.directions_car_rounded,
    Icons.flight_rounded,
    Icons.beach_access_rounded,
    Icons.sports_soccer_rounded,
    Icons.rocket_launch_rounded,
    Icons.apple_rounded,
    Icons.school_rounded,
    Icons.music_note_rounded,
    Icons.bolt_rounded,
    Icons.ac_unit_rounded,
    Icons.wb_sunny_rounded,
    Icons.forest_rounded,
    Icons.water_drop_rounded,
    Icons.local_fire_department_rounded,
    Icons.umbrella_rounded,
    Icons.park_rounded,
    Icons.toys_rounded,
    Icons.sports_basketball_rounded,
  ];

  late List<_CardItem> cards;
  _MemoryLevel level = _MemoryLevel.medium;
  int? firstIndex;
  int moves = 0;
  int matched = 0;
  bool locked = false;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  int get _pairCount {
    switch (level) {
      case _MemoryLevel.easy:
        return 8; // 16 cards
      case _MemoryLevel.medium:
        return 12; // 24 cards
      case _MemoryLevel.hard:
        return 18; // 36 cards
      case _MemoryLevel.expert:
        return 24; // 48 cards
    }
  }

  String get _levelName {
    switch (level) {
      case _MemoryLevel.easy:
        return 'سهل';
      case _MemoryLevel.medium:
        return 'متوسط';
      case _MemoryLevel.hard:
        return 'صعب';
      case _MemoryLevel.expert:
        return 'خبير';
    }
  }

  double get _iconSize {
    switch (level) {
      case _MemoryLevel.easy:
        return 42;
      case _MemoryLevel.medium:
        return 38;
      case _MemoryLevel.hard:
        return 34;
      case _MemoryLevel.expert:
        return 30;
    }
  }

  int _bestColumnCount(Size available, double spacing) {
    var bestColumns = 4;
    var bestCardSide = 0.0;
    for (var columns = 2; columns <= 12; columns++) {
      if (cards.length % columns != 0) continue;
      final rows = cards.length ~/ columns;
      if (rows < 2) continue;
      final cardWidth =
          (available.width - spacing * (columns - 1)) / columns;
      final cardHeight =
          (available.height - spacing * (rows - 1)) / rows;
      final cardSide = min(cardWidth, cardHeight);
      if (cardSide > bestCardSide) {
        bestCardSide = cardSide;
        bestColumns = columns;
      }
    }
    return bestColumns;
  }

  void _setLevel(_MemoryLevel value) {
    if (level == value) return;
    setState(() => level = value);
    _newGame();
  }

  void _newGame() {
    final List<_CardItem> list = <_CardItem>[];
    final List<IconData> selected = List<IconData>.from(icons)..shuffle(_random);
    for (int i = 0; i < _pairCount; i++) {
      list.add(_CardItem(i, selected[i]));
      list.add(_CardItem(i, selected[i]));
    }
    list.shuffle(_random);
    setState(() {
      cards = list;
      firstIndex = null;
      moves = 0;
      matched = 0;
      locked = false;
    });
    SoundService.instance.play('click.wav');
  }

  Future<void> _tap(int index) async {
    if (locked || cards[index].open || cards[index].done) return;
    await SoundService.instance.play('tap.wav');
    setState(() => cards[index].open = true);
    if (firstIndex == null) {
      firstIndex = index;
      return;
    }

    final int other = firstIndex!;
    firstIndex = null;
    moves++;

    if (cards[other].id == cards[index].id) {
      setState(() {
        cards[other].done = true;
        cards[index].done = true;
        matched += 2;
      });
      await SoundService.instance.play('pop.wav');
      if (matched == cards.length) {
        final int stars = switch (level) {
          _MemoryLevel.easy => 4,
          _MemoryLevel.medium => 6,
          _MemoryLevel.hard => 8,
          _MemoryLevel.expert => 12,
        };
        await ScoreService.instance.addStars(stars);
        await SoundService.instance.play('win.wav');
      }
    } else {
      setState(() => locked = true);
      await Future<void>.delayed(const Duration(milliseconds: 650));
      if (!mounted) return;
      setState(() {
        cards[other].open = false;
        cards[index].open = false;
        locked = false;
      });
      await SoundService.instance.play('wrong.wav');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ذاكرة الصور'),
        actions: <Widget>[IconButton(onPressed: _newGame, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(colors: <Color>[Color(0xFFEC4899), Color(0xFF8B5CF6)]),
              ),
              child: Row(children: <Widget>[
                const Icon(Icons.psychology_rounded, color: Colors.white, size: 34),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تذكّر الصور المتشابهة  •  $_levelName ${cards.length}\nالحركات: $moves',
                    style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 15, fontWeight: FontWeight.w900, height: 1.35),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 7),
            Row(
              children: <Widget>[
                Expanded(child: _LevelButton(label: 'سهل', count: 16, selected: level == _MemoryLevel.easy, onTap: () => _setLevel(_MemoryLevel.easy))),
                const SizedBox(width: 5),
                Expanded(child: _LevelButton(label: 'متوسط', count: 24, selected: level == _MemoryLevel.medium, onTap: () => _setLevel(_MemoryLevel.medium))),
                const SizedBox(width: 5),
                Expanded(child: _LevelButton(label: 'صعب', count: 36, selected: level == _MemoryLevel.hard, onTap: () => _setLevel(_MemoryLevel.hard))),
                const SizedBox(width: 5),
                Expanded(child: _LevelButton(label: 'خبير', count: 48, selected: level == _MemoryLevel.expert, onTap: () => _setLevel(_MemoryLevel.expert))),
              ],
            ),
            const SizedBox(height: 7),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final spacing = cards.length >= 36 ? 4.0 : 6.0;
                  final available = Size(constraints.maxWidth, constraints.maxHeight);
                  final columns = _bestColumnCount(available, spacing);
                  final rows = cards.length ~/ columns;
                  final cardHeight =
                      (available.height - spacing * (rows - 1)) / rows;
                  return GridView.builder(
                    padding: EdgeInsets.zero,
                    primary: false,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cards.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      mainAxisExtent: cardHeight,
                    ),
                    itemBuilder: (BuildContext context, int index) {
                      final _CardItem card = cards[index];
                      final bool visible = card.open || card.done;
                      final radius = cards.length >= 36 ? 11.0 : 16.0;
                      return Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(radius),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _tap(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(radius),
                              gradient: LinearGradient(
                                colors: visible
                                    ? <Color>[const Color(0xFFFFE4E6), const Color(0xFFEDE9FE)]
                                    : <Color>[const Color(0xFF7C3AED), const Color(0xFF06B6D4)],
                              ),
                              border: Border.all(color: Colors.white, width: cards.length >= 36 ? 1.5 : 2.5),
                              boxShadow: const <BoxShadow>[
                                BoxShadow(color: Color(0x227C3AED), blurRadius: 5, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Center(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Icon(
                                  visible ? card.icon : Icons.question_mark_rounded,
                                  color: visible ? const Color(0xFF7C3AED) : Colors.white,
                                  size: _iconSize,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

class _LevelButton extends StatelessWidget {
  const _LevelButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(13),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 43,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF7C3AED) : Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? const Color(0xFF7C3AED) : const Color(0xFFD1D5DB),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Text(
              '$label $count',
              maxLines: 1,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF374151),
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CardItem {
  _CardItem(this.id, this.icon);
  final int id;
  final IconData icon;
  bool open = false;
  bool done = false;
}
