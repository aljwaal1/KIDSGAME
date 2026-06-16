import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KidsGamesArenaApp());
}

class KidsGamesArenaApp extends StatelessWidget {
  const KidsGamesArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ملعب الأطفال',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFF8E7),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF6D28D9),
          secondary: Color(0xFFF97316),
          tertiary: Color(0xFF06B6D4),
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Color(0xFFFFF8E7),
          foregroundColor: Color(0xFF2E1065),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0xFFF3E8FF)),
          ),
        ),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: GamesHome(),
      ),
    );
  }
}

class GamesHome extends StatefulWidget {
  const GamesHome({super.key});

  @override
  State<GamesHome> createState() => _GamesHomeState();
}

class _GamesHomeState extends State<GamesHome> {
  int tab = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      HomeGamesPage(),
      TicTacToePage(),
      SlidingPuzzlePage(),
      BubbleLettersPage(),
      DeveloperPage(),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('ملعب الأطفال')),
      body: pages[tab],
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (value) => setState(() => tab = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_3x3_outlined),
            selectedIcon: Icon(Icons.grid_3x3_rounded),
            label: 'إكس أو',
          ),
          NavigationDestination(
            icon: Icon(Icons.extension_outlined),
            selectedIcon: Icon(Icons.extension_rounded),
            label: 'البزل',
          ),
          NavigationDestination(
            icon: Icon(Icons.bubble_chart_outlined),
            selectedIcon: Icon(Icons.bubble_chart_rounded),
            label: 'الحروف',
          ),
          NavigationDestination(
            icon: Icon(Icons.mail_outline_rounded),
            selectedIcon: Icon(Icons.mail_rounded),
            label: 'المطور',
          ),
        ],
      ),
    );
  }
}

class HomeGamesPage extends StatelessWidget {
  const HomeGamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: const [
        _HeroPanel(),
        SizedBox(height: 16),
        GameInfoCard(
          icon: Icons.grid_3x3_rounded,
          title: 'إكس أو',
          text: 'لعب سريع بين لاعبين على نفس الجهاز.',
          color: Color(0xFF6D28D9),
        ),
        SizedBox(height: 12),
        GameInfoCard(
          icon: Icons.extension_rounded,
          title: 'بزل الأرقام',
          text: 'حرّك الأرقام حول المربع الفارغ حتى ترتبها.',
          color: Color(0xFFF97316),
        ),
        SizedBox(height: 12),
        GameInfoCard(
          icon: Icons.bubble_chart_rounded,
          title: 'فقاعات الحروف',
          text: 'اضغط الفقاعات التي تحمل نفس الحرف المطلوب.',
          color: Color(0xFF06B6D4),
        ),
      ],
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ألعب، فكّر، وتعلّم',
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'ثلاث ألعاب خفيفة للأطفال بدون إنترنت.',
            style: TextStyle(color: Color(0xFFFFF7D6), fontSize: 16),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _BubbleDot(color: Color(0xFFFFC857)),
              SizedBox(width: 8),
              _BubbleDot(color: Color(0xFFFF6B6B)),
              SizedBox(width: 8),
              _BubbleDot(color: Color(0xFF9EF01A)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BubbleDot extends StatelessWidget {
  const _BubbleDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(radius: 12, backgroundColor: color);
  }
}

class GameInfoCard extends StatelessWidget {
  const GameInfoCard({
    super.key,
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 27,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(text, style: const TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TicTacToePage extends StatefulWidget {
  const TicTacToePage({super.key});

  @override
  State<TicTacToePage> createState() => _TicTacToePageState();
}

class _TicTacToePageState extends State<TicTacToePage> {
  List<String> board = List.filled(9, '');
  String player = 'X';
  String message = 'دور اللاعب X';
  bool finished = false;
  List<int> winLine = const [];

  void play(int index) {
    if (board[index].isNotEmpty || finished) return;
    SystemSound.play(SystemSoundType.click);
    setState(() {
      board[index] = player;
      final winner = getWinnerLine();
      if (winner != null) {
        winLine = winner;
        message = 'فاز اللاعب ${board[winner.first]}';
        finished = true;
        HapticFeedback.heavyImpact();
        SystemSound.play(SystemSoundType.alert);
      } else if (!board.contains('')) {
        message = 'تعادل';
        finished = true;
        HapticFeedback.mediumImpact();
      } else {
        player = player == 'X' ? 'O' : 'X';
        message = 'دور اللاعب $player';
      }
    });
  }

  List<int>? getWinnerLine() {
    const lines = [
      [0, 1, 2],
      [3, 4, 5],
      [6, 7, 8],
      [0, 3, 6],
      [1, 4, 7],
      [2, 5, 8],
      [0, 4, 8],
      [2, 4, 6],
    ];
    for (final line in lines) {
      final a = line[0];
      final b = line[1];
      final c = line[2];
      if (board[a].isNotEmpty && board[a] == board[b] && board[b] == board[c]) {
        return line;
      }
    }
    return null;
  }

  void reset() {
    setState(() {
      board = List.filled(9, '');
      player = 'X';
      message = 'دور اللاعب X';
      finished = false;
      winLine = const [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        GameHeader(
          title: 'إكس أو',
          subtitle: message,
          color: const Color(0xFF6D28D9),
          onReset: reset,
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final size = constraints.maxWidth;
              return Stack(
                children: [
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 9,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final value = board[index];
                      return InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => play(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: value == 'X'
                                ? const Color(0xFFEDE9FE)
                                : value == 'O'
                                    ? const Color(0xFFFFEDD5)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: winLine.contains(index)
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFE9D5FF),
                              width: winLine.contains(index) ? 4 : 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              value,
                              style: TextStyle(
                                fontSize: 54,
                                fontWeight: FontWeight.w900,
                                color: value == 'X'
                                    ? const Color(0xFF6D28D9)
                                    : const Color(0xFFF97316),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  if (winLine.isNotEmpty)
                    IgnorePointer(
                      child: CustomPaint(
                        size: Size.square(size),
                        painter: WinLinePainter(winLine),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class SlidingPuzzlePage extends StatefulWidget {
  const SlidingPuzzlePage({super.key});

  @override
  State<SlidingPuzzlePage> createState() => _SlidingPuzzlePageState();
}

class _SlidingPuzzlePageState extends State<SlidingPuzzlePage> {
  List<int> tiles = [1, 2, 3, 4, 5, 6, 7, 8, 0];
  int moves = 0;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    shuffle();
  }

  void shuffle() {
    tiles = [1, 2, 3, 4, 5, 6, 7, 8, 0];
    for (var i = 0; i < 80; i++) {
      final empty = tiles.indexOf(0);
      final neighbors = movableNeighbors(empty);
      final pick = neighbors[random.nextInt(neighbors.length)];
      final temp = tiles[empty];
      tiles[empty] = tiles[pick];
      tiles[pick] = temp;
    }
    setState(() => moves = 0);
  }

  List<int> movableNeighbors(int empty) {
    final row = empty ~/ 3;
    final col = empty % 3;
    final result = <int>[];
    if (row > 0) result.add(empty - 3);
    if (row < 2) result.add(empty + 3);
    if (col > 0) result.add(empty - 1);
    if (col < 2) result.add(empty + 1);
    return result;
  }

  void move(int index) {
    final empty = tiles.indexOf(0);
    if (!movableNeighbors(empty).contains(index)) return;
    SystemSound.play(SystemSoundType.click);
    setState(() {
      tiles[empty] = tiles[index];
      tiles[index] = 0;
      moves++;
    });
    if (solved) {
      HapticFeedback.heavyImpact();
      SystemSound.play(SystemSoundType.alert);
    }
  }

  bool get solved {
    for (var i = 0; i < 8; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return tiles[8] == 0;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        GameHeader(
          title: 'بزل الأرقام',
          subtitle: solved ? 'ممتاز، رتبت الأرقام' : 'الحركات: $moves',
          color: const Color(0xFFF97316),
          onReset: shuffle,
        ),
        const SizedBox(height: 10),
        const Text(
          'رتب الأرقام من 1 إلى 8 واترك المربع الفارغ في النهاية.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 9,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final value = tiles[index];
              final empty = value == 0;
              return InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => move(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  decoration: BoxDecoration(
                    color: empty ? const Color(0xFFFFF8E7) : const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: empty ? const Color(0xFFFCD34D) : const Color(0xFFFB923C),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      empty ? '' : '$value',
                      style: const TextStyle(
                        color: Color(0xFFC2410C),
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class BubbleLettersPage extends StatefulWidget {
  const BubbleLettersPage({super.key});

  @override
  State<BubbleLettersPage> createState() => _BubbleLettersPageState();
}

class _BubbleLettersPageState extends State<BubbleLettersPage>
    with SingleTickerProviderStateMixin {
  final Random random = Random();
  final List<String> letters = ['أ', 'ب', 'ت', 'ج', 'ح', 'د', 'ر', 'س', 'ص'];
  late String target;
  late List<String> bubbles;
  late AnimationController driftController;
  int score = 0;
  int mistakes = 0;

  @override
  void initState() {
    super.initState();
    driftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    createRound(resetScore: true);
  }

  @override
  void dispose() {
    driftController.dispose();
    super.dispose();
  }

  void createRound({bool resetScore = false}) {
    target = letters[random.nextInt(letters.length)];
    final count = 3 + random.nextInt(2);
    bubbles = List.generate(count, (_) => letters[random.nextInt(letters.length)]);
    bubbles[random.nextInt(count)] = target;
    if (resetScore) {
      score = 0;
      mistakes = 0;
    }
  }

  void newRound({bool resetScore = false}) {
    createRound(resetScore: resetScore);
    setState(() {});
  }

  void pop(int index) {
    var shouldStartNewRound = false;
    setState(() {
      if (bubbles[index] == target) {
        SystemSound.play(SystemSoundType.click);
        HapticFeedback.lightImpact();
        score++;
        bubbles[index] = '';
        if (!bubbles.contains(target)) {
          shouldStartNewRound = true;
        }
      } else {
        SystemSound.play(SystemSoundType.alert);
        mistakes++;
      }
    });
    if (shouldStartNewRound) {
      Future.delayed(const Duration(milliseconds: 250), () {
        if (mounted) newRound();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        GameHeader(
          title: 'فقاعات الحروف',
          subtitle: 'النقاط: $score',
          color: const Color(0xFF06B6D4),
          onReset: () => newRound(resetScore: true),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFE0F7FA),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFF67E8F9), width: 2),
          ),
          child: Column(
            children: [
              const Text(
                'اضغط نفس الحرف',
                style: TextStyle(
                  color: Color(0xFF0E7490),
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                target,
                style: const TextStyle(
                  color: Color(0xFF155E75),
                  fontSize: 88,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'الأخطاء: $mistakes',
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: driftController,
          builder: (context, _) {
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bubbles.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 18,
                mainAxisSpacing: 18,
              ),
              itemBuilder: (context, index) {
                final letter = bubbles[index];
                final hidden = letter.isEmpty;
                final direction = index.isEven ? 1.0 : -1.0;
                final offset = sin(driftController.value * pi * 2 + index) * 18 * direction;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: hidden ? 0.12 : 1,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: hidden ? null : () => pop(index),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: hidden
                                ? [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)]
                                : [const Color(0xFFA5F3FC), const Color(0xFF22D3EE)],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x3306B6D4),
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            letter,
                            style: const TextStyle(
                              color: Color(0xFF164E63),
                              fontSize: 50,
                              fontWeight: FontWeight.w900,
                            ),
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
      ],
    );
  }
}

class WinLinePainter extends CustomPainter {
  const WinLinePainter(this.line);

  final List<int> line;

  @override
  void paint(Canvas canvas, Size size) {
    if (line.length != 3) return;
    final cell = size.width / 3;
    Offset centerOf(int index) {
      final row = index ~/ 3;
      final col = index % 3;
      return Offset(col * cell + cell / 2, row * cell + cell / 2);
    }

    final start = centerOf(line.first);
    final end = centerOf(line.last);
    final paint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant WinLinePainter oldDelegate) {
    return oldDelegate.line.join(',') != line.join(',');
  }
}

class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onReset,
  });

  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF64748B))),
                ],
              ),
            ),
            IconButton.filledTonal(
              onPressed: onReset,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'إعادة',
            ),
          ],
        ),
      ),
    );
  }
}

class DeveloperPage extends StatefulWidget {
  const DeveloperPage({super.key});

  @override
  State<DeveloperPage> createState() => _DeveloperPageState();
}

class _DeveloperPageState extends State<DeveloperPage> {
  final noteController = TextEditingController();

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'مراسلة المطور',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const SelectableText(
                  'fastunlocked2017@gmail.com',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: noteController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'اكتب ملاحظتك',
                    filled: true,
                    fillColor: const Color(0xFFFFFBEB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () async {
                    final note = noteController.text.trim().isEmpty
                        ? 'ملاحظة على تطبيق ملعب الأطفال'
                        : noteController.text.trim();
                    await Clipboard.setData(
                      ClipboardData(
                        text: 'إلى: fastunlocked2017@gmail.com\n\n$note',
                      ),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ الرسالة')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('نسخ الرسالة'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
