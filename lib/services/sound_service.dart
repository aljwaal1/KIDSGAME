import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _player = AudioPlayer();
  final ValueNotifier<bool> mutedNotifier = ValueNotifier<bool>(false);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    mutedNotifier.value = prefs.getBool('sound_muted') ?? false;
    await _player.setReleaseMode(ReleaseMode.stop);
  }

  Future<void> play(String fileName) async {
    if (mutedNotifier.value) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/$fileName'), volume: 0.75);
    } catch (_) {
      // Keep the game stable even if a sound asset is missing on older builds.
    }
  }

  Future<void> toggleMute() async {
    mutedNotifier.value = !mutedNotifier.value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_muted', mutedNotifier.value);
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
