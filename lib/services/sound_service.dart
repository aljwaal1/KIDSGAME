import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SoundLevel { high, medium, low, muted }

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final AudioPlayer _uiPlayer = AudioPlayer(playerId: 'ui-effects');
  final AudioPlayer _gamePlayer = AudioPlayer(playerId: 'game-effects');
  final AudioPlayer _celebrationPlayer = AudioPlayer(playerId: 'celebration-effects');

  final ValueNotifier<SoundLevel> levelNotifier = ValueNotifier<SoundLevel>(SoundLevel.medium);
  final ValueNotifier<bool> mutedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> lastErrorNotifier = ValueNotifier<String?>(null);

  SoundLevel _lastAudibleLevel = SoundLevel.medium;

  static const Set<String> _uiSounds = <String>{'click.wav', 'tap.wav'};
  static const Set<String> _celebrationSounds = <String>{'win.wav', 'chime.wav'};

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLevel = _parseLevel(prefs.getString('sound_level'));
    final legacyMuted = prefs.getBool('sound_muted') ?? false;
    final initialLevel = savedLevel ?? (legacyMuted ? SoundLevel.muted : SoundLevel.medium);

    levelNotifier.value = initialLevel;
    mutedNotifier.value = initialLevel == SoundLevel.muted;
    if (initialLevel != SoundLevel.muted) _lastAudibleLevel = initialLevel;

    await Future.wait(<Future<void>>[
      _configurePlayer(_uiPlayer, PlayerMode.lowLatency),
      _configurePlayer(_gamePlayer, PlayerMode.lowLatency),
      _configurePlayer(_celebrationPlayer, PlayerMode.mediaPlayer),
    ]);
  }

  SoundLevel? _parseLevel(String? value) {
    for (final level in SoundLevel.values) {
      if (level.name == value) return level;
    }
    return null;
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

  double _baseVolumeFor(String fileName) {
    if (_uiSounds.contains(fileName)) return 0.58;
    if (_celebrationSounds.contains(fileName)) return 0.75;
    return 0.68;
  }

  double get _levelFactor {
    switch (levelNotifier.value) {
      case SoundLevel.high:
        return 1.0;
      case SoundLevel.medium:
        return 0.65;
      case SoundLevel.low:
        return 0.35;
      case SoundLevel.muted:
        return 0.0;
    }
  }

  double _volumeFor(String fileName) {
    return (_baseVolumeFor(fileName) * _levelFactor).clamp(0.0, 1.0).toDouble();
  }

  Future<bool> play(String fileName) async {
    if (levelNotifier.value == SoundLevel.muted) return false;

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

  Future<void> setLevel(SoundLevel level) async {
    if (levelNotifier.value == level) return;

    if (level != SoundLevel.muted) _lastAudibleLevel = level;
    levelNotifier.value = level;
    mutedNotifier.value = level == SoundLevel.muted;
    if (level == SoundLevel.muted) await stopAll();

    final prefs = await SharedPreferences.getInstance();
    await Future.wait(<Future<bool>>[
      prefs.setString('sound_level', level.name),
      prefs.setBool('sound_muted', level == SoundLevel.muted),
    ]);
  }

  Future<void> toggleMute() async {
    if (levelNotifier.value == SoundLevel.muted) {
      await setLevel(_lastAudibleLevel);
    } else {
      _lastAudibleLevel = levelNotifier.value;
      await setLevel(SoundLevel.muted);
    }
  }

  Future<void> dispose() async {
    await Future.wait(<Future<void>>[
      _uiPlayer.dispose(),
      _gamePlayer.dispose(),
      _celebrationPlayer.dispose(),
    ]);
  }
}
