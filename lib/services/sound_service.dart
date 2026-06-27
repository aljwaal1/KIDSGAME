import 'package:flutter/foundation.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final ValueNotifier<bool> mutedNotifier = ValueNotifier<bool>(false);

  Future<void> init() async {}

  Future<void> play(String fileName) async {
    if (mutedNotifier.value) return;
    // Safe no-op fallback. Keeps the app stable even if sound assets change.
  }

  Future<void> toggleMute() async {
    mutedNotifier.value = !mutedNotifier.value;
  }
}
