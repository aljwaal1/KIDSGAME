import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class DeveloperPage extends StatelessWidget {
  const DeveloperPage({super.key});

  static const List<(String, String, IconData)> _sounds = <(String, String, IconData)>[
    ('click.wav', 'نقرة الواجهة', Icons.touch_app_rounded),
    ('tap.wav', 'لمس اللعبة', Icons.ads_click_rounded),
    ('move.wav', 'حركة', Icons.open_with_rounded),
    ('pop.wav', 'إجابة صحيحة', Icons.bubble_chart_rounded),
    ('wrong.wav', 'إجابة خاطئة', Icons.error_outline_rounded),
    ('chime.wav', 'إكمال مرحلة', Icons.music_note_rounded),
    ('win.wav', 'فوز', Icons.emoji_events_rounded),
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
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(colors: <Color>[Color(0xFF7C3AED), Color(0xFF06B6D4)]),
          ),
          child: const Row(
            children: <Widget>[
              Icon(Icons.settings_suggest_rounded, color: Colors.white, size: 44),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'أدوات الفحص\nالنسخة الحديثة 1.2.0+3',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, fontFamily: 'Changa'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('اختبار الأصوات', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900, fontFamily: 'Changa')),
                const SizedBox(height: 6),
                ValueListenableBuilder<bool>(
                  valueListenable: SoundService.instance.mutedNotifier,
                  builder: (context, muted, _) => Text(
                    muted ? 'الصوت مكتوم حاليًا. شغّله من أعلى التطبيق قبل الاختبار.' : 'اضغط على كل زر للتأكد من سماع المؤثر.',
                    style: TextStyle(color: muted ? const Color(0xFFDC2626) : const Color(0xFF64748B)),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    for (final sound in _sounds)
                      FilledButton.tonalIcon(
                        onPressed: () => SoundService.instance.play(sound.$1),
                        icon: Icon(sound.$3),
                        label: Text(sound.$2),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<String?>(
                  valueListenable: SoundService.instance.lastErrorNotifier,
                  builder: (context, error, _) {
                    if (error == null) {
                      return const Row(
                        children: <Widget>[
                          Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
                          SizedBox(width: 8),
                          Expanded(child: Text('لم يُسجّل خطأ صوتي في الجلسة الحالية.')),
                        ],
                      );
                    }
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(error, style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          TextButton.icon(
                            onPressed: SoundService.instance.clearLastError,
                            icon: const Icon(Icons.clear_rounded),
                            label: const Text('مسح الخطأ'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.delete_sweep_rounded)),
            title: const Text('إعادة ضبط التقدم', style: TextStyle(fontWeight: FontWeight.w900)),
            subtitle: const Text('حذف النجوم وأفضل النتائج فقط'),
            trailing: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
            onTap: () => _resetProgress(context),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'ملعب الأطفال تطبيق ألعاب تعليمية وذهنية يعمل دون إنترنت. صفحة الفحص مخصصة للتحقق من الصوت والتقدم المحفوظ.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.6),
            ),
          ),
        ),
      ],
    );
  }
}
