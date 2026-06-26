import 'package:flutter/material.dart';

import '../games/memory_pairs_page.dart';
import '../games/mini_sudoku_page.dart';
import '../games/pattern_challenge_page.dart';
import '../games/quick_math_page.dart';
import '../games/smart_maze_page.dart';
import '../services/score_service.dart';
import '../widgets/mascot_painter.dart';

class HomeGamesPage extends StatelessWidget {
  const HomeGamesPage({super.key, required this.onSelectGame});

  /// Called with the bottom-navigation tab index of the chosen game.
  final ValueChanged<int> onSelectGame;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        const _HeroPanel(),
        const SizedBox(height: 16),
        GameInfoCard(
          icon: Icons.grid_3x3_rounded,
          title: 'إكس أو',
          text: 'لعب سريع بين لاعبين، أو تحدَّ الكمبيوتر.',
          color: const Color(0xFF6D28D9),
          onTap: () => onSelectGame(1),
        ),
        const SizedBox(height: 12),
        GameInfoCard(
          icon: Icons.extension_rounded,
          title: 'بزل الأرقام',
          text: 'حرّك الأرقام حول المربع الفارغ حتى ترتبها.',
          color: const Color(0xFFF97316),
          onTap: () => onSelectGame(2),
        ),
        const SizedBox(height: 12),
        GameInfoCard(
          icon: Icons.bubble_chart_rounded,
          title: 'فقاعات الحروف',
          text: 'اضغط الفقاعات التي تحمل نفس الحرف المطلوب.',
          color: const Color(0xFF06B6D4),
          onTap: () => onSelectGame(3),
        ),
        const SizedBox(height: 18),
        const Text(
          'ألعاب ذكاء وتفكير',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Changa'),
        ),
        const SizedBox(height: 12),
        GameInfoCard(
          icon: Icons.psychology_rounded,
          title: 'ذاكرة الصور',
          text: 'افتح البطاقات وتذكّر أماكن الصور المتشابهة.',
          color: const Color(0xFFEC4899),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MemoryPairsPage())),
        ),
        const SizedBox(height: 12),
        GameInfoCard(
          icon: Icons.auto_awesome_rounded,
          title: 'تحدي الأنماط',
          text: 'اكتشف الشكل الناقص في السلسلة.',
          color: const Color(0xFF0EA5E9),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatternChallengePage())),
        ),
        const SizedBox(height: 12),
        GameInfoCard(
          icon: Icons.grid_view_rounded,
          title: 'سودوكو الأطفال',
          text: 'لغز 4×4 بسيط يقوي المنطق والتركيز.',
          color: const Color(0xFFF97316),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MiniSudokuPage())),
        ),
        const SizedBox(height: 12),
        GameInfoCard(
          icon: Icons.route_rounded,
          title: 'المتاهة الذكية',
          text: 'حرّك البطل للوصول إلى النجمة بأقل خطوات.',
          color: const Color(0xFF22C55E),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SmartMazePage())),
        ),
        const SizedBox(height: 12),
        GameInfoCard(
          icon: Icons.calculate_rounded,
          title: 'الحساب السريع',
          text: 'اختر ناتج الجمع والطرح بسرعة وتركيز.',
          color: const Color(0xFF7C3AED),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickMathPage())),
        ),
        const SizedBox(height: 20),
        const _TipsCard(),
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x337C3AED),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ألعب، فكّر، وتعلّم',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Changa',
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'ألعاب ممتعة للأطفال، بدون إنترنت.',
                  style: TextStyle(color: Color(0xFFFFF7D6), fontSize: 15),
                ),
                SizedBox(height: 16),
                _StarsBadge(),
              ],
            ),
          ),
          SizedBox(width: 10),
          StarMascot(size: 92, mood: MascotMood.happy),
        ],
      ),
    );
  }
}

class _StarsBadge extends StatelessWidget {
  const _StarsBadge();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: ScoreService.instance.totalStars,
      builder: (context, snapshot) {
        final stars = snapshot.data ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.18),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFFFD65C), size: 20),
              const SizedBox(width: 6),
              Text(
                '$stars نجمة',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );
      },
    );
  }
}

class GameInfoCard extends StatelessWidget {
  const GameInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String text;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.75)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
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
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Changa',
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(text, style: const TextStyle(color: Color(0xFF64748B))),
                  ],
                ),
              ),
              Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lightbulb_rounded, color: Color(0xFFD97706)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'العب مع طفلك لتشجيعه، واجمعوا النجوم معًا!',
              style: TextStyle(color: Color(0xFF92400E), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
