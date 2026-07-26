import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class DeveloperPage extends StatelessWidget {
  const DeveloperPage({super.key});

  static const List<(String, String)> _sounds = <(String, String)>[
    ('نقرة', 'click.wav'),
    ('لمس', 'tap.wav'),
    ('حركة', 'move.wav'),
    ('صحيح', 'pop.wav'),
    ('خطأ', 'wrong.wav'),
    ('إكمال', 'chime.wav'),
    ('فوز', 'win.wav'),
  ];

  Future<void> _resetProgress(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعادة ضبط التقدم'),
        content: const Text('سيتم حذف النجوم وأفضل النتائج المحفوظة. هل تريد المتابعة؟'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('حذف التقدم')),
        ],
      ),
    );
    if (confirmed != true) return;
    await ScoreService.instance.resetProgress();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تمت إعادة ضبط التقدم')));
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(colors: <Color>[Color(0xFF334155), Color(0xFF0F766E)]),
          ),
          child: const Row(children: <Widget>[
            Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 44),
            SizedBox(width: 12),
            Expanded(child: Text('فحص التطبيق\nاختبر الصوت وإدارة التقدم', style: TextStyle(color: Colors.white, fontFamily: 'Changa', fontSize: 20, fontWeight: FontWeight.w900))),
          ]),
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              const Text('اختبار الأصوات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, fontFamily: 'Changa')),
              const SizedBox(height: 6),
              const Text('ارفع صوت الوسائط في الهاتف، ثم اضغط كل زر.', style: TextStyle(color: Color(0xFF64748B))),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final sound in _sounds)
                    FilledButton.tonalIcon(
                      onPressed: () => SoundService.instance.play(sound.$2),
                      icon: const Icon(Icons.volume_up_rounded),
                      label: Text(sound.$1),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<String?>(
                valueListenable: SoundService.instance.lastErrorNotifier,
                builder: (context, error, _) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: error == null ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: error == null ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5)),
                  ),
                  child: Text(error ?? 'لم يتم تسجيل خطأ صوتي', style: TextStyle(color: error == null ? const Color(0xFF166534) : const Color(0xFF991B1B), fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              const Text('التقدم المحفوظ', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, fontFamily: 'Changa')),
              const SizedBox(height: 10),
              ValueListenableBuilder<int>(
                valueListenable: ScoreService.instance.starsNotifier,
                builder: (context, stars, _) => Text('النجوم الحالية: $stars ⭐', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _resetProgress(context),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('إعادة ضبط التقدم'),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        const Center(child: Text('ملعب الأطفال • النسخة الحديثة Flutter', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w700))),
      ],
    );
  }
}
