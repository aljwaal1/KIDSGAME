import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Plays short sound effects for the games and remembers whether the user muted the app.
class SoundService {
  SoundService._internal();

  static final SoundService instance = SoundService._internal();

  final AudioPlayer _player = AudioPlayer(playerId: 'kga_sfx_player');
  final ValueNotifier<bool> mutedNotifier = ValueNotifier<bool>(false);

  bool _ready = false;

  bool get muted => mutedNotifier.value;

  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    try {
      await _player.setPlayerMode(PlayerMode.lowLatency);
      await _player.setReleaseMode(ReleaseMode.stop);
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      mutedNotifier.value = prefs.getBool('kga_muted') ?? false;
    } catch (_) {}
  }

  Future<void> toggleMute() async {
    mutedNotifier.value = !mutedNotifier.value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('kga_muted', mutedNotifier.value);
    } catch (_) {}
  }

  Future<void> play(String fileName) async {
    if (mutedNotifier.value) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/$fileName'));
    } catch (_) {}
  }
}
