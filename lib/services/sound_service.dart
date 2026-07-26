import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _uiPlayer = AudioPlayer(playerId: 'ui-effects');
  final AudioPlayer _gamePlayer = AudioPlayer(playerId: 'game-effects');
  final AudioPlayer _celebrationPlayer = AudioPlayer(playerId: 'celebration-effects');

  final ValueNotifier<bool> mutedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> lastErrorNotifier = ValueNotifier<String?>(null);

  static const Set<String> _uiSounds = <String>{'click.wav', 'tap.wav'};
  static const Set<String> _celebrationSounds = <String>{'win.wav', 'chime.wav'};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    mutedNotifier.value = prefs.getBool('sound_muted') ?? false;

    await Future.wait(<Future<void>>[
      _configurePlayer(_uiPlayer, PlayerMode.lowLatency),
      _configurePlayer(_gamePlayer, PlayerMode.lowLatency),
      _configurePlayer(_celebrationPlayer, PlayerMode.mediaPlayer),
    ]);
  }

  Future<void> _configurePlayer(AudioPlayer player, PlayerMode mode) async {
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setPlayerMode(mode);
  }

  AudioPlayer _playerFor(String fileName) {
    if (_uiSounds.contains(fileName)) return _uiPlayer;
    if (_celebrationSounds.contains(fileName)) return _celebrationPlayer;
    return _gamePlayer;
  }

  double _volumeFor(String fileName) {
    if (_uiSounds.contains(fileName)) return 0.85;
    if (_celebrationSounds.contains(fileName)) return 1.0;
    return 0.95;
  }

  Future<bool> play(String fileName) async {
    if (mutedNotifier.value) return false;

    final player = _playerFor(fileName);
    try {
      lastErrorNotifier.value = null;
      await player.stop();
      await player.play(
        AssetSource('sounds/$fileName'),
        volume: _volumeFor(fileName),
        mode: _celebrationSounds.contains(fileName) ? PlayerMode.mediaPlayer : PlayerMode.lowLatency,
      );
      return true;
    } catch (error, stackTrace) {
      final message = 'تعذر تشغيل $fileName: $error';
      lastErrorNotifier.value = message;
      debugPrint(message);
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> stopAll() async {
    await Future.wait(<Future<void>>[
      _uiPlayer.stop(),
      _gamePlayer.stop(),
      _celebrationPlayer.stop(),
    ]);
  }

  Future<void> toggleMute() async {
    mutedNotifier.value = !mutedNotifier.value;
    if (mutedNotifier.value) await stopAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_muted', mutedNotifier.value);
  }

  Future<void> dispose() async {
    await Future.wait(<Future<void>>[
      _uiPlayer.dispose(),
      _gamePlayer.dispose(),
      _celebrationPlayer.dispose(),
    ]);
  }
}
