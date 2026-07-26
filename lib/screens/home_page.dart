import 'package:flutter/material.dart';

import '../games/capital_letter_coloring_page.dart';
import '../games/dahdel_page.dart';
import '../games/memory_pairs_page.dart';
import '../games/mini_sudoku_page.dart';
import '../games/odd_one_out_page.dart';
import '../games/pattern_challenge_page.dart';
import '../games/pebble_harra_page.dart';
import '../games/quick_math_page.dart';
import '../games/ring_guess_page.dart';
import '../games/seega_page.dart';
import '../games/sequence_order_page.dart';
import '../games/seven_stones_page.dart';
import '../games/shape_shadow_page.dart';
import '../games/smart_maze_page.dart';
import '../services/score_service.dart';
import '../services/sound_service.dart';
import '../widgets/mascot_painter.dart';

class HomeGamesPage extends StatefulWidget {
  const HomeGamesPage({super.key, required this.onSelectGame});
  final ValueChanged<int> onSelectGame;

  @override
  State<HomeGamesPage> createState() => _HomeGamesPageState();
}

class _HomeGamesPageState extends State<HomeGamesPage> {
  int section = 0;

  @override
  Widget build(BuildContext context) {
    final sections = <_GameSection>[
      _GameSection('الأساسية', const Color(0xFF6D28D9), <_GameItem>[
        _GameItem(Icons.grid_3x3_rounded, 'إكس أو', 'صديق أو كمبيوتر', const Color(0xFF6D28D9), () => widget.onSelectGame(1)),
        _GameItem(Icons.extension_rounded, 'بزل الأرقام', '3×3 و 4×4', const Color(0xFFF97316), () => widget.onSelectGame(2)),
        _GameItem(Icons.bubble_chart_rounded, 'فقاعات الحروف', 'التقط الحرف', const Color(0xFF06B6D4), () => widget.onSelectGame(3)),
      ]),
      _GameSection('الذكاء', const Color(0xFF0EA5E9), <_GameItem>[
        _GameItem(Icons.psychology_rounded, 'ذاكرة الصور', 'تذكر البطاقات', const Color(0xFFEC4899), () => _open(const MemoryPairsPage())),
        _GameItem(Icons.auto_awesome_rounded, 'تحدي الأنماط', 'الشكل الناقص', const Color(0xFF0EA5E9), () => _open(const PatternChallengePage())),
        _GameItem(Icons.grid_view_rounded, 'سودوكو الأطفال', 'منطق 4×4', const Color(0xFFF97316), () => _open(const MiniSudokuPage())),
        _GameItem(Icons.route_rounded, 'المتاهة الذكية', 'وصل للنجمة', const Color(0xFF22C55E), () => _open(const SmartMazePage())),
        _GameItem(Icons.calculate_rounded, 'الحساب السريع', 'جمع وطرح', const Color(0xFF7C3AED), () => _open(const QuickMathPage())),
      ]),
      _GameSection('الملاحظة', const Color(0xFF14B8A6), <_GameItem>[
        _GameItem(Icons.visibility_rounded, 'ابحث عن المختلف', 'اختر المختلف', const Color(0xFF14B8A6), () => _open(const OddOneOutPage())),
        _GameItem(Icons.filter_vintage_rounded, 'ظل الشكل', 'طابق الظل', const Color(0xFF8B5CF6), () => _open(const ShapeShadowPage())),
        _GameItem(Icons.sort_rounded, 'رتّب التسلسل', 'رتب العناصر', const Color(0xFFEF4444), () => _open(const SequenceOrderPage())),
      ]),
      _GameSection('التعليم', const Color(0xFF4F46E5), <_GameItem>[
        _GameItem(Icons.draw_rounded, 'تلوين الحروف الكبيرة', 'اتبع السهم', const Color(0xFF4F46E5), () => _open(const CapitalLetterColoringPage())),
      ]),
      _GameSection('تراث', const Color(0xFFB45309), <_GameItem>[
        _GameItem(Icons.scatter_plot_rounded, 'الحَرّة بالحصى', 'ثلاث حصوات على خط', const Color(0xFFB45309), () => _open(const PebbleHarraPage())),
        _GameItem(Icons.sports_baseball_rounded, 'الدحدل', 'دحرج نحو الهدف', const Color(0xFF0F766E), () => _open(const DahdelPage())),
        _GameItem(Icons.layers_rounded, 'سبع حجارة', 'ابنِ البرج بدقة', const Color(0xFFF97316), () => _open(const SevenStonesPage())),
        _GameItem(Icons.grid_4x4_rounded, 'السيجا', 'حصى وحركة وأكل', const Color(0xFF1E3A8A), () => _open(const SeegaPage())),
        _GameItem(Icons.diamond_rounded, 'الخاتم', 'اختر اليد الصحيحة', const Color(0xFFF59E0B), () => _open(const RingGuessPage())),
      ]),
    ];

    final current = sections[section];
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Column(
        children: <Widget>[
          const _HeroPanel(),
          const SizedBox(height: 10),
          _SectionTabs(
            sections: sections,
            selected: section,
            onSelect: (index) {
              SoundService.instance.play('click.wav');
              setState(() => section = index);
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Icon(Icons.apps_rounded, color: current.color),
              const SizedBox(width: 8),
              Text(current.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Changa')),
              const Spacer(),
              Text('${current.items.length} ألعاب', style: const TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(child: _GamesGrid(items: current.items)),
        ],
      ),
    );
  }

  void _open(Widget page) {
    SoundService.instance.play('click.wav');
    Navigator.push(context, MaterialPageRoute<void>(builder: (_) => page));
  }
}

class _GameSection {
  const _GameSection(this.title, this.color, this.items);
  final String title;
  final Color color;
  final List<_GameItem> items;
}

class _GameItem {
  const _GameItem(this.icon, this.title, this.text, this.color, this.onTap);
  final IconData icon;
  final String title;
  final String text;
  final Color color;
  final VoidCallback onTap;
}

class _SectionTabs extends StatelessWidget {
  const _SectionTabs({required this.sections, required this.selected, required this.onSelect});
  final List<_GameSection> sections;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (var i = 0; i < sections.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(start: i == 0 ? 0 : 5),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onSelect(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == i ? sections[i].color : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: selected == i ? sections[i].color : const Color(0xFFE2E8F0)),
                    boxShadow: selected == i ? <BoxShadow>[BoxShadow(color: sections[i].color.withAlpha(50), blurRadius: 10, offset: const Offset(0, 4))] : null,
                  ),
                  child: Text(
                    sections[i].title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: selected == i ? Colors.white : const Color(0xFF475569), fontWeight: FontWeight.w900, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _GamesGrid extends StatelessWidget {
  const _GamesGrid({required this.items});
  final List<_GameItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxRows = items.length <= 4 ? 2 : 3;
        final cardHeight = ((constraints.maxHeight - ((maxRows - 1) * 8)) / maxRows).clamp(70.0, 108.0).toDouble();
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final item in items)
              SizedBox(width: (constraints.maxWidth - 8) / 2, height: cardHeight, child: _CompactGameCard(item: item)),
          ],
        );
      },
    );
  }
}

class _CompactGameCard extends StatelessWidget {
  const _CompactGameCard({required this.item});
  final _GameItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Row(children: <Widget>[
              Container(width: 38, height: 38, decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(colors: <Color>[item.color, item.color.withAlpha(190)]), boxShadow: <BoxShadow>[BoxShadow(color: item.color.withAlpha(70), blurRadius: 8, offset: const Offset(0, 3))]), child: Icon(item.icon, color: Colors.white, size: 20)),
              const Spacer(),
              Icon(Icons.arrow_back_ios_new_rounded, size: 13, color: item.color),
            ]),
            const Spacer(),
            Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, fontFamily: 'Changa')),
            const SizedBox(height: 2),
            Text(item.text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 112,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(28), gradient: const LinearGradient(colors: <Color>[Color(0xFF7C3AED), Color(0xFF06B6D4)], begin: Alignment.topRight, end: Alignment.bottomLeft), boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x337C3AED), blurRadius: 18, offset: Offset(0, 8))]),
      child: const Row(crossAxisAlignment: CrossAxisAlignment.center, children: <Widget>[
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
          Text('ألعب، فكّر، وتعلّم', style: TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w800, fontFamily: 'Changa')),
          SizedBox(height: 6),
          Text('اختر قسمًا وابدأ اللعب بدون تمرير.', style: TextStyle(color: Color(0xFFFFF7D6), fontSize: 13)),
          SizedBox(height: 8),
          _StarsBadge(),
        ])),
        SizedBox(width: 8),
        StarMascot(size: 74, mood: MascotMood.happy),
      ]),
    );
  }
}

class _StarsBadge extends StatelessWidget {
  const _StarsBadge();
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ScoreService.instance.totalStarsNotifier,
      builder: (context, stars, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: const Color(0x2EFFFFFF), borderRadius: BorderRadius.circular(999), border: Border.all(color: const Color(0x66FFFFFF))),
          child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
            const Icon(Icons.star_rounded, color: Color(0xFFFFD65C), size: 18),
            const SizedBox(width: 5),
            Text('$stars نجمة', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
          ]),
        );
      },
    );
  }
}
