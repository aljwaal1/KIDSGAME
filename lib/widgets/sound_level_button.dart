import 'package:flutter/material.dart';

import '../services/sound_service.dart';

String soundLevelLabel(SoundLevel level) {
  switch (level) {
    case SoundLevel.high:
      return 'عالٍ';
    case SoundLevel.medium:
      return 'متوسط';
    case SoundLevel.low:
      return 'خفيف';
    case SoundLevel.muted:
      return 'كتم';
  }
}

IconData soundLevelIcon(SoundLevel level) {
  switch (level) {
    case SoundLevel.high:
      return Icons.volume_up_rounded;
    case SoundLevel.medium:
      return Icons.volume_down_rounded;
    case SoundLevel.low:
      return Icons.volume_mute_rounded;
    case SoundLevel.muted:
      return Icons.volume_off_rounded;
  }
}

class SoundLevelButton extends StatelessWidget {
  const SoundLevelButton({super.key, this.showLabel = false});

  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SoundLevel>(
      valueListenable: SoundService.instance.levelNotifier,
      builder: (context, level, _) {
        final label = soundLevelLabel(level);
        return PopupMenuButton<SoundLevel>(
          tooltip: 'مستوى الصوت: $label',
          initialValue: level,
          onSelected: (selected) => SoundService.instance.setLevel(selected),
          itemBuilder: (context) => <PopupMenuEntry<SoundLevel>>[
            for (final option in SoundLevel.values)
              PopupMenuItem<SoundLevel>(
                value: option,
                child: Row(
                  children: <Widget>[
                    Icon(soundLevelIcon(option), size: 22),
                    const SizedBox(width: 10),
                    Expanded(child: Text(soundLevelLabel(option), style: const TextStyle(fontWeight: FontWeight.w700))),
                    if (option == level) const Icon(Icons.check_rounded, size: 20),
                  ],
                ),
              ),
          ],
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: showLabel ? 12 : 10, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(soundLevelIcon(level)),
                if (showLabel) ...<Widget>[
                  const SizedBox(width: 6),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class SoundLevelOverlay extends StatelessWidget {
  const SoundLevelOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(child: child),
        SafeArea(
          top: false,
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 12,
            child: SizedBox(
              height: 52,
              child: Row(
                children: <Widget>[
                  const SizedBox(width: 12),
                  const Icon(Icons.settings_voice_rounded, size: 19, color: Color(0xFF64748B)),
                  const SizedBox(width: 7),
                  const Text('صوت اللعبة', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF475569))),
                  const Spacer(),
                  DecoratedBox(
                    decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(15)),
                    child: const SoundLevelButton(showLabel: true),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
