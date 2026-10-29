import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'game_audio_catalog.dart';
import 'game_audio_event.dart';

enum SoundLevel { high, medium, low, muted }

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final Map<AudioChannel, AudioPlayer> _players = <AudioChannel, AudioPlayer>{
    AudioChannel.ui: AudioPlayer(playerId: 'ui-effects'),
    AudioChannel.action: AudioPlayer(playerId: 'action-effects'),
    AudioChannel.impact: AudioPlayer(playerId: 'impact-effects'),
    AudioChannel.result: AudioPlayer(playerId: 'result-effects'),
    AudioChannel.voice: AudioPlayer(playerId: 'voice-assets'),
  };
  final Map<GameSoundEvent, DateTime> _lastPlayed = <GameSoundEvent, DateTime>{};

  final ValueNotifier<SoundLevel> levelNotifier = ValueNotifier<SoundLevel>(SoundLevel.medium);
  final ValueNotifier<bool> mutedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> lastErrorNotifier = ValueNotifier<String?>(null);
  SoundLevel _lastAudibleLevel = SoundLevel.medium;

  bool get isMuted => levelNotifier.value == SoundLevel.muted;
  double get levelFactor => switch (levelNotifier.value) {
        SoundLevel.high => 1.0,
        SoundLevel.medium => .65,
        SoundLevel.low => .35,
        SoundLevel.muted => 0.0,
      };

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLevel = _parseLevel(prefs.getString('sound_level'));
    final legacyMuted = prefs.getBool('sound_muted') ?? false;
    final initialLevel = savedLevel ?? (legacyMuted ? SoundLevel.muted : SoundLevel.medium);
    levelNotifier.value = initialLevel;
    mutedNotifier.value = initialLevel == SoundLevel.muted;
    if (initialLevel != SoundLevel.muted) _lastAudibleLevel = initialLevel;
    await Future.wait(_players.entries.map((entry) async {
      await entry.value.setReleaseMode(ReleaseMode.stop);
      await entry.value.setPlayerMode(
        entry.key == AudioChannel.result || entry.key == AudioChannel.voice
            ? PlayerMode.mediaPlayer
            : PlayerMode.lowLatency,
      );
    }));
  }

  SoundLevel? _parseLevel(String? value) {
    for (final level in SoundLevel.values) {
      if (level.name == value) return level;
    }
    return null;
  }

  Future<bool> playEvent(GameSoundEvent event, {double volumeBoost = 1.0}) async {
    if (isMuted) return false;
    final cue = GameAudioCatalog.cueFor(event);
    final now = DateTime.now();
    final previous = _lastPlayed[event];
    if (previous != null && now.difference(previous) < cue.cooldown) return false;
    _lastPlayed[event] = now;
    return _playAsset(cue.asset, cue.channel, cue.gain * volumeBoost);
  }

  Future<bool> playVoiceAsset(String fileName, {double gain = 1.0}) {
    if (isMuted) return Future<bool>.value(false);
    return _playAsset(fileName, AudioChannel.voice, gain);
  }

  Future<bool> _playAsset(String asset, AudioChannel channel, double gain) async {
    final player = _players[channel]!;
    try {
      lastErrorNotifier.value = null;
      await player.stop();
      await player.play(
        AssetSource('sounds/$asset'),
        volume: (gain * levelFactor).clamp(0.0, 1.0).toDouble(),
        mode: channel == AudioChannel.result || channel == AudioChannel.voice
            ? PlayerMode.mediaPlayer
            : PlayerMode.lowLatency,
      );
      return true;
    } catch (error, stackTrace) {
      final message = 'تعذر تشغيل $asset: $error';
      lastErrorNotifier.value = message;
      debugPrint(message);
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> play(String fileName, {double volumeBoost = 1.0}) {
    final channel = <String>{'click.wav', 'tap.wav'}.contains(fileName)
        ? AudioChannel.ui
        : <String>{'win.wav', 'chime.wav'}.contains(fileName)
            ? AudioChannel.result
            : AudioChannel.action;
    return _playAsset(fileName, channel, .68 * volumeBoost);
  }

  Future<void> stopVoiceAwareAudio() => Future.wait(<Future<void>>[
        _players[AudioChannel.voice]!.stop(),
        _players[AudioChannel.ui]!.stop(),
      ]);

  Future<void> stopAll() => Future.wait(_players.values.map((player) => player.stop()));

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
    if (isMuted) {
      await setLevel(_lastAudibleLevel);
    } else {
      _lastAudibleLevel = levelNotifier.value;
      await setLevel(SoundLevel.muted);
    }
  }

  Future<void> dispose() => Future.wait(_players.values.map((player) => player.dispose()));
}
