import 'package:flutter/material.dart';
import '../services/score_service.dart';
import '../services/sound_service.dart';

class MemoryPairsPage extends StatefulWidget {
  const MemoryPairsPage({super.key});
  @override
  State<MemoryPairsPage> createState() => _MemoryPairsPageState();
}

class _MemoryPairsPageState extends State<MemoryPairsPage> {
  final List<String> icons = <String>['🍎','🚗','⭐','🐱','🍎','🚗','⭐','🐱'];
  final Set<int> open = <int>{};
  final Set<int> done = <int>{};
  int? first;
  int moves = 0;

  @override
  void initState() { super.initState(); icons.shuffle(); }

  void tap(int i) {
    if (open.contains(i) || done.contains(i)) return;
    SoundService.instance.play('click.wav');
    setState(() { open.add(i); });
    if (first == null) { first = i; return; }
    moves++;
    final a = first!;
    first = null;
    if (icons[a] == icons[i]) {
      done.addAll(<int>[a, i]);
      ScoreService.instance.addStars(1);
      if (done.length == icons.length) SoundService.instance.play('win.wav');
      setState(() {});
    } else {
      Future<void>.delayed(const Duration(milliseconds: 650), () {
        if (!mounted) return;
        setState(() { open.remove(a); open.remove(i); });
      });
    }
  }

  void reset() { setState(() { icons.shuffle(); open.clear(); done.clear(); first = null; moves = 0; }); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ذاكرة الصور - $moves حركة'), actions: [IconButton(onPressed: reset, icon: const Icon(Icons.refresh_rounded))]),
      body: GridView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: icons.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14),
        itemBuilder: (context, i) {
          final show = open.contains(i) || done.contains(i);
          return InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => tap(i),
            child: Card(child: Center(child: Text(show ? icons[i] : '؟', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900)))),
          );
        },
      ),
    );
  }
}
