import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/score_service.dart';
import '../widgets/mascot_painter.dart';

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

  Future<void> _confirmResetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('إعادة ضبط التقدم'),
          content: const Text(
            'سيتم حذف عدد النجوم وأفضل النتائج المحفوظة. لا يمكن التراجع عن هذا الإجراء.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('إعادة الضبط'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await ScoreService.instance.resetProgress();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم إعادة ضبط التقدم')),
    );
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
                const Row(
                  children: [
                    StarMascot(size: 44, mood: MascotMood.happy),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'مراسلة المطور',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Changa',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'حول التطبيق',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Changa',
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'ملعب الأطفال — إصدار 1.1.0',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _confirmResetProgress,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('إعادة ضبط النجوم والنتائج'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
