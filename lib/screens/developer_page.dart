import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const String developerEmail = 'fastunlocked2017@gmail.com';

class DeveloperPage extends StatelessWidget {
  const DeveloperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF06B6D4)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.mail_rounded, color: Colors.white, size: 38),
              SizedBox(height: 12),
              Text(
                'تواصل مع المطور',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'Changa'),
              ),
              SizedBox(height: 8),
              Text(
                'أرسل ملاحظاتك واقتراحاتك لتطوير ألعاب الأطفال.',
                style: TextStyle(color: Color(0xFFFFF7D6), fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.alternate_email_rounded, color: Color(0xFF7C3AED)),
            title: const Text(developerEmail, textDirection: TextDirection.ltr),
            subtitle: const Text('اضغط لنسخ البريد'),
            onTap: () async {
              await Clipboard.setData(const ClipboardData(text: developerEmail));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم نسخ البريد')));
              }
            },
          ),
        ),
      ],
    );
  }
}
