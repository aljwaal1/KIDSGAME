from pathlib import Path
import shutil

ROOT = Path.cwd()
SRC = Path(__file__).resolve().parent

NEW_FILES = [
    'lib/games/memory_pairs_page.dart',
    'lib/games/pattern_challenge_page.dart',
    'lib/games/mini_sudoku_page.dart',
    'lib/games/smart_maze_page.dart',
    'lib/games/quick_math_page.dart',
]

for rel in NEW_FILES:
    src = SRC / rel
    dst = ROOT / rel
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, dst)

home = ROOT / 'lib/screens/home_page.dart'
text = home.read_text(encoding='utf-8')

imports = """import '../games/memory_pairs_page.dart';
import '../games/mini_sudoku_page.dart';
import '../games/pattern_challenge_page.dart';
import '../games/quick_math_page.dart';
import '../games/smart_maze_page.dart';
"""
if "memory_pairs_page.dart" not in text:
    text = text.replace("import '../services/score_service.dart';\n", "import '../services/score_service.dart';\n" + imports)

text = text.replace("ثلاث ألعاب ممتعة للأطفال، بدون إنترنت.", "سبع ألعاب ممتعة للأطفال، بدون إنترنت.")

old = """        const SizedBox(height: 12),
        GameInfoCard(
          icon: Icons.bubble_chart_rounded,
          title: 'فقاعات الحروف',
          text: 'اضغط الفقاعات التي تحمل نفس الحرف المطلوب.',
          color: const Color(0xFF06B6D4),
          onTap: () => onSelectGame(3),
        ),
        const SizedBox(height: 20),
        const _TipsCard(),
"""
new = """        const SizedBox(height: 12),
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
"""
if "ذاكرة الصور" not in text:
    if old not in text:
        raise SystemExit('لم أجد مكان إضافة الألعاب في home_page.dart. تأكد أن الملف لم يتغير كثيرًا.')
    text = text.replace(old, new)

home.write_text(text, encoding='utf-8')

pub = ROOT / 'pubspec.yaml'
if pub.exists():
    p = pub.read_text(encoding='utf-8')
    p = p.replace('version: 1.1.0+2', 'version: 1.2.0+3')
    pub.write_text(p, encoding='utf-8')

print('تم تطبيق تحديث KIDSGAME: إضافة ألعاب الذكاء والتفكير.')
