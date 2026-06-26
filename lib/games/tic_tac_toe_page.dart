import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class TicTacToePage extends StatefulWidget {
  const TicTacToePage({super.key});

  @override
  State<TicTacToePage> createState() => _TicTacToePageState();
}

class _TicTacToePageState extends State<TicTacToePage> {
  final List<String> board = List.filled(9, '');
  String turn = 'X';
  String message = 'دور X';
  bool finished = false;

  void _tap(int i) async {
    if (board[i].isNotEmpty || finished) return;
    await SoundService.instance.play('click.wav');
    setState(() {
      board[i] = turn;
      final winner = _winner();
      if (winner != null) {
        message = 'الفائز $winner 🎉';
        finished = true;
        ScoreService.instance.addStars(2);
        SoundService.instance.play('win.wav');
      } else if (!board.contains('')) {
        message = 'تعادل جميل';
        finished = true;
      } else {
        turn = turn == 'X' ? 'O' : 'X';
        message = 'دور $turn';
      }
    });
  }

  String? _winner() {
    const lines = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];
    for (final l in lines) {
      if (board[l[0]].isNotEmpty && board[l[0]] == board[l[1]] && board[l[1]] == board[l[2]]) {
        return board[l[0]];
      }
    }
    return null;
  }

  void _reset() {
    setState(() {
      for (var i = 0; i < board.length; i++) board[i] = '';
      turn = 'X';
      message = 'دور X';
      finished = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        _Header(title: 'إكس أو', text: message, icon: Icons.grid_3x3_rounded, color: const Color(0xFF7C3AED)),
        const SizedBox(height: 18),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 9,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10),
          itemBuilder: (context, i) => InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => _tap(i),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              alignment: Alignment.center,
              child: Text(board[i], style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: board[i] == 'X' ? const Color(0xFF7C3AED) : const Color(0xFF06B6D4))),
            ),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(onPressed: _reset, icon: const Icon(Icons.refresh_rounded), label: const Text('جولة جديدة')),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.text, required this.icon, required this.color});
  final String title;
  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        Icon(icon, color: Colors.white, size: 36),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Changa')),
          const SizedBox(height: 4),
          Text(text, style: const TextStyle(color: Color(0xFFFFF7D6))),
        ])),
      ]),
    );
  }
}
