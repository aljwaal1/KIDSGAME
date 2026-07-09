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

  int get _columns => 4;

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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(colors: <Color>[Color(0xFFEC4899), Color(0xFF8B5CF6)]),
              ),
              child: Row(children: <Widget>[
                const Icon(Icons.psychology_rounded, color: Colors.white, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'تذكّر الصور المتشابهة\n$_levelName: ${cards.length} بطاقة • الحركات: $moves',
                    style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              alignment: WrapAlignment.center,
              children: <Widget>[
                ChoiceChip(label: const Text('سهل 16'), selected: level == _MemoryLevel.easy, onSelected: (_) => _setLevel(_MemoryLevel.easy)),
                ChoiceChip(label: const Text('متوسط 24'), selected: level == _MemoryLevel.medium, onSelected: (_) => _setLevel(_MemoryLevel.medium)),
                ChoiceChip(label: const Text('صعب 36'), selected: level == _MemoryLevel.hard, onSelected: (_) => _setLevel(_MemoryLevel.hard)),
                ChoiceChip(label: const Text('خبير 48'), selected: level == _MemoryLevel.expert, onSelected: (_) => _setLevel(_MemoryLevel.expert)),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                itemCount: cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _columns,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: level == _MemoryLevel.expert ? .74 : .78,
                ),
                itemBuilder: (BuildContext context, int index) {
                  final _CardItem card = cards[index];
                  final bool visible = card.open || card.done;
                  return Card(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => _tap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            colors: visible
                                ? <Color>[const Color(0xFFFFE4E6), const Color(0xFFEDE9FE)]
                                : <Color>[const Color(0xFF7C3AED), const Color(0xFF06B6D4)],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            visible ? card.icon : Icons.question_mark_rounded,
                            color: visible ? const Color(0xFF7C3AED) : Colors.white,
                            size: _iconSize,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
