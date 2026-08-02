import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';
import '../widgets/confetti_overlay.dart';
import '../widgets/game_header.dart';

class _PuzzlePicture {
  const _PuzzlePicture(this.name, this.asset, this.emoji, this.color);

  final String name;
  final String asset;
  final String emoji;
  final Color color;
}

class AnimalPicturePuzzlePage extends StatefulWidget {
  const AnimalPicturePuzzlePage({super.key});

  @override
  State<AnimalPicturePuzzlePage> createState() => _AnimalPicturePuzzlePageState();
}

class _AnimalPicturePuzzlePageState extends State<AnimalPicturePuzzlePage> {
  static const List<_PuzzlePicture> pictures = <_PuzzlePicture>[
    _PuzzlePicture('الدب', 'assets/images/puzzle/bear.webp', '🐻', Color(0xFF9A5A2A)),
    _PuzzlePicture('القط', 'assets/images/puzzle/cat.webp', '🐱', Color(0xFFF28C28)),
    _PuzzlePicture('الأسد', 'assets/images/puzzle/lion.webp', '🦁', Color(0xFFE6A11A)),
  ];

  final Random random = Random();
  final GlobalKey<ConfettiOverlayState> confettiKey = GlobalKey<ConfettiOverlayState>();
  int pictureIndex = 0;
  int gridSize = 3;
  int moves = 0;
  int? bestMoves;
  int? selectedTile;
  bool solvedCelebrated = false;
  late List<int> tiles;

  _PuzzlePicture get picture => pictures[pictureIndex];
  String get scoreKey => 'animal_picture_${picture.name}_$gridSize';

  @override
  void initState() {
    super.initState();
    tiles = _orderedTiles();
    _shuffle();
    _loadBest();
  }

  List<int> _orderedTiles() {
    final count = gridSize * gridSize;
    return List<int>.generate(count, (index) => index);
  }

  Future<void> _loadBest() async {
    final value = await ScoreService.instance.getBestMoves(scoreKey);
    if (mounted) setState(() => bestMoves = value);
  }

  void _choosePicture(int index) {
    if (index == pictureIndex) return;
    SoundService.instance.play('click.wav');
    setState(() => pictureIndex = index);
    _shuffle();
    _loadBest();
  }

  void _setGridSize(int value) {
    if (gridSize == value) return;
    SoundService.instance.play('click.wav');
    setState(() {
      gridSize = value;
      tiles = _orderedTiles();
    });
    _shuffle();
    _loadBest();
  }

  void _shuffle() {
    tiles = _orderedTiles();
    do {
      tiles.shuffle(random);
    } while (_isSolved);
    setState(() {
      moves = 0;
      solvedCelebrated = false;
      selectedTile = null;
    });
  }

  void _swapTiles(int sourceValue, int targetValue) {
    if (sourceValue == targetValue) return;
    final sourceIndex = tiles.indexOf(sourceValue);
    final targetIndex = tiles.indexOf(targetValue);
    SoundService.instance.play('move.wav');
    HapticFeedback.selectionClick();
    setState(() {
      tiles[sourceIndex] = targetValue;
      tiles[targetIndex] = sourceValue;
      moves++;
      selectedTile = null;
    });
    if (_isSolved && !solvedCelebrated) _celebrate();
  }

  void _selectOrSwap(int value) {
    if (selectedTile == null) {
      SoundService.instance.play('click.wav');
      setState(() => selectedTile = value);
      return;
    }
    if (selectedTile == value) {
      setState(() => selectedTile = null);
      return;
    }
    _swapTiles(selectedTile!, value);
  }

  bool get _isSolved {
    final ordered = _orderedTiles();
    for (var index = 0; index < tiles.length; index++) {
      if (tiles[index] != ordered[index]) return false;
    }
    return true;
  }

  Future<void> _celebrate() async {
    solvedCelebrated = true;
    HapticFeedback.heavyImpact();
    SoundService.instance.play('win.wav');
    confettiKey.currentState?.burst();
    await ScoreService.instance.addStars(gridSize == 3 ? 2 : 3);
    final isNewBest = await ScoreService.instance.reportMoves(scoreKey, moves);
    if (isNewBest && mounted) setState(() => bestMoves = moves);
  }

  @override
  Widget build(BuildContext context) {
    final bestText = bestMoves == null ? '' : '  •  الأفضل: $bestMoves';
    return Scaffold(
      body: SafeArea(
        child: ConfettiOverlay(
          key: confettiKey,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
            child: Column(
              children: <Widget>[
                GameHeader(
                  title: 'بازل الحيوانات',
                  subtitle: _isSolved ? 'رائع! اكتملت صورة ${picture.name} 🎉' : 'الحركات: $moves$bestText',
                  color: const Color(0xFF10B981),
                  onReset: _shuffle,
                ),
                const SizedBox(height: 8),
                _buildPicturePicker(),
                const SizedBox(height: 8),
                _buildReferenceRow(),
                const SizedBox(height: 5),
                const Text('اسحب أي قطعة فوق أي قطعة أخرى لتبديل مكانهما', style: TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Expanded(child: _buildPuzzle()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPicturePicker() {
    return Row(
      children: <Widget>[
        for (var index = 0; index < pictures.length; index++)
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: index == 0 ? 0 : 6),
              child: ChoiceChip(
                avatar: Text(pictures[index].emoji),
                label: Text(pictures[index].name),
                selected: pictureIndex == index,
                onSelected: (_) => _choosePicture(index),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReferenceRow() {
    return Container(
      height: 96,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: picture.color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: picture.color.withAlpha(80), width: 1.5),
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(picture.asset, width: 80, height: 80, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('الصورة الأصلية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, fontFamily: 'Changa')),
                SizedBox(height: 2),
                Text('استعن بها أثناء ترتيب القطع', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              _DifficultyButton(label: '3×3', selected: gridSize == 3, onTap: () => _setGridSize(3)),
              const SizedBox(height: 5),
              _DifficultyButton(label: '4×4', selected: gridSize == 4, onTap: () => _setGridSize(4)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzle() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.maxWidth;
            final cell = size / gridSize;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x220F172A), blurRadius: 14, offset: Offset(0, 7))],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: Stack(
                  children: <Widget>[
                    for (var value = 0; value < gridSize * gridSize; value++)
                      _buildTile(value, cell, size),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTile(int value, double cell, double boardSize) {
    final currentIndex = tiles.indexOf(value);
    final currentRow = currentIndex ~/ gridSize;
    final currentColumn = currentIndex % gridSize;
    final originalIndex = value;
    final originalRow = originalIndex ~/ gridSize;
    final originalColumn = originalIndex % gridSize;
    return AnimatedPositioned(
      key: ValueKey<String>('animal_${pictureIndex}_${gridSize}_$value'),
      duration: const Duration(milliseconds: 190),
      curve: Curves.easeOutCubic,
      top: currentRow * cell,
      left: currentColumn * cell,
      width: cell,
      height: cell,
      child: DragTarget<int>(
        onWillAccept: (sourceValue) => sourceValue != null && sourceValue != value,
        onAccept: (sourceValue) => _swapTiles(sourceValue, value),
        builder: (context, candidates, rejected) {
          final highlighted = candidates.isNotEmpty || selectedTile == value;
          return Draggable<int>(
            data: value,
            maxSimultaneousDrags: _isSolved ? 0 : 1,
            feedback: Material(
              color: Colors.transparent,
              elevation: 10,
              borderRadius: BorderRadius.circular(14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(picture.asset, width: cell * .82, height: cell * .82, fit: BoxFit.cover),
              ),
            ),
            childWhenDragging: Opacity(opacity: .25, child: _buildPiece(cell, boardSize, originalRow, originalColumn, highlighted)),
            child: GestureDetector(
              onTap: () => _selectOrSwap(value),
              child: _buildPiece(cell, boardSize, originalRow, originalColumn, highlighted),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPiece(double cell, double boardSize, int originalRow, int originalColumn, bool highlighted) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        border: Border.all(
          color: highlighted ? const Color(0xFFFFD54F) : Colors.white,
          width: highlighted ? 4 : (gridSize == 3 ? 2 : 1.4),
        ),
      ),
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          minWidth: boardSize,
          maxWidth: boardSize,
          minHeight: boardSize,
          maxHeight: boardSize,
          child: Transform.translate(
            offset: Offset(-originalColumn * cell, -originalRow * cell),
            child: Image.asset(picture.asset, width: boardSize, height: boardSize, fit: BoxFit.cover),
          ),
        ),
      ),
    );
  }
}

class _DifficultyButton extends StatelessWidget {
  const _DifficultyButton({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 54,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF10B981) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFF10B981) : const Color(0xFFCBD5E1)),
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.white : const Color(0xFF475569), fontWeight: FontWeight.w900)),
      ),
    );
  }
}