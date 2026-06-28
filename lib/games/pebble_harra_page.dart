import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class PebbleHarraPage extends StatefulWidget {
  const PebbleHarraPage({super.key});

  @override
  State<PebbleHarraPage> createState() => _PebbleHarraPageState();
}

class _PebbleHarraPageState extends State<PebbleHarraPage> {
  static const List<List<int>> winLines = <List<int>>[
    <int>[0, 1, 2], <int>[3, 4, 5], <int>[6, 7, 8],
    <int>[0, 3, 6], <int>[1, 4, 7], <int>[2, 5, 8],
    <int>[0, 4, 8], <int>[2, 4, 6],
  ];

  static const List<List<int>> neighbors = <List<int>>[
    <int>[1, 3, 4],
    <int>[0, 2, 4],
    <int>[1, 5, 4],
    <int>[0, 4, 6],
    <int>[0, 1, 2, 3, 5, 6, 7, 8],
    <int>[2, 4, 8],
    <int>[3, 7, 4],
    <int>[6, 8, 4],
    <int>[5, 7, 4],
  ];

  final List<int> board = List<int>.filled(9, 0);
  int player = 1;
  int redPlaced = 0;
  int bluePlaced = 0;
  int? selected;
  int redWins = 0;
  int blueWins = 0;
  bool finished = false;
  List<int> winningLine = <int>[];

  bool get placingPhase => redPlaced < 3 || bluePlaced < 3;
  String get playerName => player == 1 ? 'الأحمر' : 'الأزرق';
  Color get playerColor => player == 1 ? const Color(0xFFEF4444) : const Color(0xFF2563EB);
  String get phaseText => placingPhase ? 'ضع الحصى على اللوحة' : 'حرّك حصاة إلى مكان قريب';

  void reset() {
    setState(() {
      for (var i = 0; i < board.length; i++) {
        board[i] = 0;
      }
      player = 1;
      redPlaced = 0;
      bluePlaced = 0;
      selected = null;
      finished = false;
      winningLine = <int>[];
    });
    SoundService.instance.play('click.wav');
  }

  Future<void> tapCell(int index) async {
    if (finished) return;

    if (placingPhase) {
      if (board[index] != 0) return;
      setState(() {
        board[index] = player;
        if (player == 1) {
          redPlaced++;
        } else {
          bluePlaced++;
        }
      });
      await SoundService.instance.play('move.wav');
      await afterMove();
      return;
    }

    if (selected == null) {
      if (board[index] != player) return;
      setState(() => selected = index);
      SoundService.instance.play('tap.wav');
      return;
    }

    if (board[index] == player) {
      setState(() => selected = index);
      SoundService.instance.play('tap.wav');
      return;
    }

    final from = selected!;
    if (board[index] != 0 || !neighbors[from].contains(index)) {
      SoundService.instance.play('wrong.wav');
      return;
    }

    setState(() {
      board[index] = player;
      board[from] = 0;
      selected = null;
    });
    await SoundService.instance.play('move.wav');
    await afterMove();
  }

  Future<void> afterMove() async {
    final line = getWinningLine(player);
    if (line.isNotEmpty) {
      setState(() {
        finished = true;
        winningLine = line;
        if (player == 1) {
          redWins++;
        } else {
          blueWins++;
        }
      });
      await ScoreService.instance.addStars(2);
      await SoundService.instance.play('win.wav');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فاز $playerName! ثلاث حصوات على خط واحد')));
      }
      return;
    }

    setState(() {
      player = player == 1 ? 2 : 1;
      selected = null;
    });
  }

  List<int> getWinningLine(int owner) {
    for (final line in winLines) {
      if (board[line[0]] == owner && board[line[1]] == owner && board[line[2]] == owner) return line;
    }
    return <int>[];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الحَرّة بالحصى'), actions: <Widget>[IconButton(onPressed: reset, icon: const Icon(Icons.refresh_rounded))]),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
        child: Column(
          children: <Widget>[
            _HeritageHeader(playerName: playerName, playerColor: playerColor, phaseText: phaseText, redWins: redWins, blueWins: blueWins),
            const SizedBox(height: 10),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      return CustomPaint(
                        painter: _HarraBoardPainter(winningLine: winningLine),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(14),
                          itemCount: 9,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 18, crossAxisSpacing: 18),
                          itemBuilder: (context, index) => _PebbleCell(
                            owner: board[index],
                            selected: selected == index,
                            highlighted: winningLine.contains(index),
                            onTap: () => tapCell(index),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            _RulesBox(placingPhase: placingPhase),
          ],
        ),
      ),
    );
  }
}

class _HeritageHeader extends StatelessWidget {
  const _HeritageHeader({required this.playerName, required this.playerColor, required this.phaseText, required this.redWins, required this.blueWins});
  final String playerName;
  final Color playerColor;
  final String phaseText;
  final int redWins;
  final int blueWins;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 108,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(colors: <Color>[Color(0xFF92400E), Color(0xFFF59E0B)], begin: Alignment.topRight, end: Alignment.bottomLeft),
        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x3392400E), blurRadius: 14, offset: Offset(0, 7))],
      ),
      child: Row(children: <Widget>[
        Container(width: 48, height: 48, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFF7ED)), child: Icon(Icons.scatter_plot_rounded, color: playerColor, size: 30)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text('دور $playerName', style: const TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(phaseText, style: const TextStyle(color: Color(0xFFFFF7D6), fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text('الأحمر $redWins  •  الأزرق $blueWins', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
        ])),
      ]),
    );
  }
}

class _PebbleCell extends StatelessWidget {
  const _PebbleCell({required this.owner, required this.selected, required this.highlighted, required this.onTap});
  final int owner;
  final bool selected;
  final bool highlighted;
  final VoidCallback onTap;

  Color get color {
    if (owner == 1) return const Color(0xFFEF4444);
    if (owner == 2) return const Color(0xFF2563EB);
    return const Color(0xFFE7C99A);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: owner == 0 ? const Color(0xFFFFF7ED) : color,
          border: Border.all(color: highlighted ? const Color(0xFF22C55E) : selected ? const Color(0xFFFFD65C) : const Color(0xFFB45309), width: highlighted || selected ? 5 : 3),
          boxShadow: <BoxShadow>[BoxShadow(color: color.withAlpha(owner == 0 ? 40 : 90), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Center(
          child: owner == 0
              ? const Icon(Icons.circle_outlined, color: Color(0xFFB45309), size: 26)
              : Icon(Icons.circle, color: Colors.white.withAlpha(220), size: 24),
        ),
      ),
    );
  }
}

class _HarraBoardPainter extends CustomPainter {
  const _HarraBoardPainter({required this.winningLine});
  final List<int> winningLine;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF92400E)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final w = size.width;
    final h = size.height;
    final points = <Offset>[
      Offset(w * .20, h * .20), Offset(w * .50, h * .20), Offset(w * .80, h * .20),
      Offset(w * .20, h * .50), Offset(w * .50, h * .50), Offset(w * .80, h * .50),
      Offset(w * .20, h * .80), Offset(w * .50, h * .80), Offset(w * .80, h * .80),
    ];
    final lines = <List<int>>[
      <int>[0, 1, 2], <int>[3, 4, 5], <int>[6, 7, 8],
      <int>[0, 3, 6], <int>[1, 4, 7], <int>[2, 5, 8],
      <int>[0, 4, 8], <int>[2, 4, 6],
    ];
    for (final line in lines) {
      canvas.drawLine(points[line.first], points[line.last], paint);
    }
    if (winningLine.isNotEmpty) {
      final winPaint = Paint()
        ..color = const Color(0xFF22C55E)
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(points[winningLine.first], points[winningLine.last], winPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HarraBoardPainter oldDelegate) => oldDelegate.winningLine != winningLine;
}

class _RulesBox extends StatelessWidget {
  const _RulesBox({required this.placingPhase});
  final bool placingPhase;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFFBBF24))),
      child: Row(children: <Widget>[
        const Icon(Icons.info_rounded, color: Color(0xFFB45309)),
        const SizedBox(width: 8),
        Expanded(child: Text(placingPhase ? 'ضع 3 حصوات لكل لاعب، ثم حاول تكوين خط.' : 'اختر حصاة ثم حرّكها لمكان قريب. الفائز يصنع خطًا من 3.', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF78350F), fontWeight: FontWeight.w700))),
      ]),
    );
  }
}
