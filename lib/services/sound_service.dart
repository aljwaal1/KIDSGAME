import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  static const Set<String> _uiSounds = <String>{'click.wav', 'tap.wav'};
  static const Set<String> _celebrationSounds = <String>{'win.wav', 'chime.wav'};

  final List<AudioPlayer> _uiPlayers = <AudioPlayer>[
    AudioPlayer(),
    AudioPlayer(),
  ];
  final List<AudioPlayer> _effectPlayers = <AudioPlayer>[
    AudioPlayer(),
    AudioPlayer(),
    AudioPlayer(),
  ];
  final AudioPlayer _celebrationPlayer = AudioPlayer();

  final ValueNotifier<bool> mutedNotifier = ValueNotifier<bool>(false);
  final ValueNotifier<String?> lastErrorNotifier = ValueNotifier<String?>(null);

  Future<void>? _initFuture;
  int _uiIndex = 0;
  int _effectIndex = 0;
  int _celebrationToken = 0;

  Future<void> init() => _initFuture ??= _initInternal();

  Future<void> _initInternal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      mutedNotifier.value = prefs.getBool('sound_muted') ?? false;

      final players = <AudioPlayer>[
        ..._uiPlayers,
        ..._effectPlayers,
        _celebrationPlayer,
      ];
      await Future.wait(<Future<void>>[
        for (final player in players) ...<Future<void>>[
          player.setPlayerMode(PlayerMode.lowLatency),
          player.setReleaseMode(ReleaseMode.stop),
        ],
      ]);
      lastErrorNotifier.value = null;
    } catch (error, stackTrace) {
      _reportError('تعذر تهيئة الصوت', error, stackTrace);
    }
  }

  Future<void> play(String fileName) async {
    if (mutedNotifier.value) return;
    await init();
    if (mutedNotifier.value) return;

    try {
      if (_celebrationSounds.contains(fileName)) {
        await _playCelebration(fileName);
        return;
      }

      final isUiSound = _uiSounds.contains(fileName);
      final player = isUiSound ? _nextUiPlayer() : _nextEffectPlayer();
      await player.stop();
      await player.play(
        AssetSource('sounds/$fileName'),
        volume: isUiSound ? 0.92 : 1.0,
      );
      lastErrorNotifier.value = null;
    } catch (error, stackTrace) {
      _reportError('فشل تشغيل $fileName', error, stackTrace);
    }
  }

  AudioPlayer _nextUiPlayer() {
    final player = _uiPlayers[_uiIndex % _uiPlayers.length];
    _uiIndex++;
    return player;
  }

  AudioPlayer _nextEffectPlayer() {
    final player = _effectPlayers[_effectIndex % _effectPlayers.length];
    _effectIndex++;
    return player;
  }

  Future<void> _playCelebration(String fileName) async {
    final token = ++_celebrationToken;
    final repeats = fileName == 'win.wav' ? 3 : 2;

    for (var i = 0; i < repeats; i++) {
      if (token != _celebrationToken || mutedNotifier.value) return;
      await _celebrationPlayer.stop();
      await _celebrationPlayer.play(
        AssetSource('sounds/$fileName'),
        volume: 1.0,
      );
      if (i < repeats - 1) {
        await Future<void>.delayed(
          Duration(milliseconds: fileName == 'win.wav' ? 170 : 145),
        );
      }
    }
    lastErrorNotifier.value = null;
  }

  Future<void> toggleMute() async {
    mutedNotifier.value = !mutedNotifier.value;
    if (mutedNotifier.value) {
      await stopAll();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sound_muted', mutedNotifier.value);
  }

  Future<void> stopAll() async {
    _celebrationToken++;
    await Future.wait(<Future<void>>[
      for (final player in <AudioPlayer>[
        ..._uiPlayers,
        ..._effectPlayers,
        _celebrationPlayer,
      ])
        player.stop(),
    ]);
  }

  void clearLastError() {
    lastErrorNotifier.value = null;
  }

  void _reportError(String message, Object error, StackTrace stackTrace) {
    final details = '$message: $error';
    lastErrorNotifier.value = details;
    debugPrint(details);
    debugPrintStack(stackTrace: stackTrace);
  }

  Future<void> dispose() async {
    await stopAll();
    await Future.wait(<Future<void>>[
      for (final player in <AudioPlayer>[
        ..._uiPlayers,
        ..._effectPlayers,
        _celebrationPlayer,
      ])
        player.dispose(),
    ]);
  }
}
