import 'package:flutter/material.dart';

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
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Changa',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
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
