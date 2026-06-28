import 'dart:math';
import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class MemoryPairsPage extends StatefulWidget {
  const MemoryPairsPage({super.key});
  @override
  State<MemoryPairsPage> createState() => _MemoryPairsPageState();
}

class _MemoryPairsPageState extends State<MemoryPairsPage> {
  final Random _random = Random();
  final List<IconData> icons = const <IconData>[Icons.star_rounded, Icons.favorite_rounded, Icons.pets_rounded, Icons.local_florist_rounded];
  late List<_CardItem> cards;
  int? firstIndex;
  int moves = 0;
  int matched = 0;

  @override
  void initState() {
    super.initState();
    _newGame();
  }

  void _newGame() {
    final List<_CardItem> list = <_CardItem>[];
    for (int i = 0; i < icons.length; i++) {
      list.add(_CardItem(i, icons[i]));
      list.add(_CardItem(i, icons[i]));
    }
    list.shuffle(_random);
    setState(() {
      cards = list;
      firstIndex = null;
      moves = 0;
      matched = 0;
    });
    SoundService.instance.play('click.wav');
  }

  Future<void> _tap(int index) async {
    if (cards[index].open || cards[index].done) return;
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
        await ScoreService.instance.addStars(4);
        await SoundService.instance.play('win.wav');
      }
    } else {
      await Future<void>.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      setState(() {
        cards[other].open = false;
        cards[index].open = false;
      });
      await SoundService.instance.play('wrong.wav');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ذاكرة الصور'), actions: <Widget>[IconButton(onPressed: _newGame, icon: const Icon(Icons.refresh_rounded))]),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          children: <Widget>[
            Container(
              height: 92,
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(colors: <Color>[Color(0xFFEC4899), Color(0xFF8B5CF6)])),
              child: Row(children: <Widget>[
                const Icon(Icons.psychology_rounded, color: Colors.white, size: 42),
                const SizedBox(width: 12),
                Expanded(child: Text('تذكّر الصور المتشابهة\nالحركات: $moves', style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 20, fontWeight: FontWeight.w900))),
              ]),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: .78),
                itemBuilder: (BuildContext context, int index) {
                  final _CardItem card = cards[index];
                  return Card(child: InkWell(borderRadius: BorderRadius.circular(22), onTap: () => _tap(index), child: AnimatedContainer(duration: const Duration(milliseconds: 200), decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: LinearGradient(colors: card.open || card.done ? <Color>[const Color(0xFFFFE4E6), const Color(0xFFEDE9FE)] : <Color>[const Color(0xFF7C3AED), const Color(0xFF06B6D4)])), child: Center(child: Icon(card.open || card.done ? card.icon : Icons.question_mark_rounded, color: card.open || card.done ? const Color(0xFF7C3AED) : Colors.white, size: 40)))));
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
