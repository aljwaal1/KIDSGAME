import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _uiPlayer = AudioPlayer();
  final AudioPlayer _gamePlayer = AudioPlayer();
  final ValueNotifier<bool> mutedNotifier = ValueNotifier<bool>(false);

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    mutedNotifier.value = prefs.getBool('sound_muted') ?? false;
    await Future.wait(<Future<void>>[
      _uiPlayer.setReleaseMode(ReleaseMode.stop),
      _gamePlayer.setReleaseMode(ReleaseMode.stop),
    ]);
  }

  Future<void> play(String fileName) async {
    if (mutedNotifier.value) return;
    try {
      final isUiSound = fileName == 'click.wav' || fileName == 'tap.wav';
      final player = isUiSound ? _uiPlayer : _gamePlayer;
      await player.stop();
      await player.play(
        AssetSource('sounds/$fileName'),
        volume: isUiSound ? 0.55 : 0.78,
      );
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
    await Future.wait(<Future<void>>[
      _uiPlayer.dispose(),
      _gamePlayer.dispose(),
    ]);
  }
}
