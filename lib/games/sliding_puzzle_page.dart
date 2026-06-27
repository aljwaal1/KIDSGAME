import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/score_service.dart';
import '../services/sound_service.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/game_header.dart';

enum PuzzleDifficulty { easy, hard }

class SlidingPuzzlePage extends StatefulWidget {
  const SlidingPuzzlePage({super.key});
  @override
  State<SlidingPuzzlePage> createState() => _SlidingPuzzlePageState();
}

class _SlidingPuzzlePageState extends State<SlidingPuzzlePage> {
  PuzzleDifficulty difficulty = PuzzleDifficulty.easy;
  int gridSize = 3;
  late List<int> tiles;
  int moves = 0;
  bool solvedCelebrated = false;
  int? bestMoves;
  final Random random = Random();
  final GlobalKey<ConfettiOverlayState> confettiKey = GlobalKey<ConfettiOverlayState>();
  String get difficultyKey => gridSize == 3 ? 'easy3' : 'hard4';

  @override
  void initState() { super.initState(); tiles = _orderedTiles(); shuffle(); _loadBest(); }

  List<int> _orderedTiles() {
    final count = gridSize * gridSize;
    return List<int>.generate(count, (i) => (i + 1) % count);
  }

  Future<void> _loadBest() async {
    final value = await ScoreService.instance.getBestMoves(difficultyKey);
    if (mounted) setState(() => bestMoves = value);
  }

  void setDifficulty(PuzzleDifficulty value) {
    if (difficulty == value) return;
    SoundService.instance.play('click.wav');
    setState(() { difficulty = value; gridSize = value == PuzzleDifficulty.easy ? 3 : 4; tiles = _orderedTiles(); });
    shuffle();
    _loadBest();
  }

  void shuffle() {
    tiles = _orderedTiles();
    final steps = gridSize * gridSize * 28;
    for (var i = 0; i < steps; i++) {
      final empty = tiles.indexOf(0);
      final neighbors = movableNeighbors(empty);
      final pick = neighbors[random.nextInt(neighbors.length)];
      final temp = tiles[empty];
      tiles[empty] = tiles[pick];
      tiles[pick] = temp;
    }
    setState(() { moves = 0; solvedCelebrated = false; });
  }

  List<int> movableNeighbors(int empty) {
    final row = empty ~/ gridSize;
    final col = empty % gridSize;
    final result = <int>[];
    if (row > 0) result.add(empty - gridSize);
    if (row < gridSize - 1) result.add(empty + gridSize);
    if (col > 0) result.add(empty - 1);
    if (col < gridSize - 1) result.add(empty + 1);
    return result;
  }

  void move(int index) {
    final empty = tiles.indexOf(0);
    if (!movableNeighbors(empty).contains(index)) return;
    SoundService.instance.play('move.wav');
    setState(() { tiles[empty] = tiles[index]; tiles[index] = 0; moves++; });
    if (solved && !solvedCelebrated) {
      solvedCelebrated = true;
      HapticFeedback.heavyImpact();
      SoundService.instance.play('win.wav');
      confettiKey.currentState?.burst();
      final stars = moves <= gridSize * gridSize * 3 ? 3 : 1;
      ScoreService.instance.addStars(stars);
      ScoreService.instance.reportMoves(difficultyKey, moves).then((isNewBest) { if (isNewBest && mounted) setState(() => bestMoves = moves); });
    }
  }

  bool get solved {
    final count = gridSize * gridSize;
    for (var i = 0; i < count - 1; i++) { if (tiles[i] != i + 1) return false; }
    return tiles[count - 1] == 0;
  }

  @override
  Widget build(BuildContext context) {
    final bestText = bestMoves != null ? '  •  أفضل نتيجة: $bestMoves' : '';
    return ConfettiOverlay(
      key: confettiKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          GameHeader(title: 'بزل الأرقام', subtitle: solved ? 'ممتاز، رتبت الأرقام 🎉' : 'الحركات: $moves$bestText', color: const Color(0xFFF97316), onReset: shuffle),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ChoiceChip(label: const Text('سهل 3×3'), selected: difficulty == PuzzleDifficulty.easy, onSelected: (_) => setDifficulty(PuzzleDifficulty.easy))),
            const SizedBox(width: 10),
            Expanded(child: ChoiceChip(label: const Text('صعب 4×4'), selected: difficulty == PuzzleDifficulty.hard, onSelected: (_) => setDifficulty(PuzzleDifficulty.hard))),
          ]),
          const SizedBox(height: 12),
          const Text('رتب الأرقام بالترتيب واترك المربع الفارغ في النهاية.', style: TextStyle(color: Color(0xFF64748B))),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(builder: (context, constraints) {
              final totalSize = constraints.maxWidth;
              final cell = totalSize / gridSize;
              return Stack(children: [for (var value = 1; value < gridSize * gridSize; value++) _buildTile(value, cell)]);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTile(int value, double cell) {
    final index = tiles.indexOf(value);
    final row = index ~/ gridSize;
    final col = index % gridSize;
    return AnimatedPositioned(
      key: ValueKey<String>('puzzle_tile_$value'),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      left: col * cell,
      top: row * cell,
      width: cell,
      height: cell,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => move(index),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFD9A8), Color(0xFFFB923C)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Color(0x33C2410C), blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Center(child: Text('$value', style: TextStyle(color: Colors.white, fontSize: gridSize == 3 ? 32 : 24, fontWeight: FontWeight.w800))),
          ),
        ),
      ),
    );
  }
}
