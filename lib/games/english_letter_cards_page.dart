import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../services/sound_service.dart';

class EnglishLetterCardsPage extends StatefulWidget {
  const EnglishLetterCardsPage({super.key});

  @override
  State<EnglishLetterCardsPage> createState() => _EnglishLetterCardsPageState();
}

class _EnglishLetterCardsPageState extends State<EnglishLetterCardsPage> {
  static const List<String> _letters = <String>[
    'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
  ];

  static const List<List<Color>> _gradients = <List<Color>>[
    <Color>[Color(0xFF2563EB), Color(0xFF06B6D4)],
    <Color>[Color(0xFF7C3AED), Color(0xFFEC4899)],
    <Color>[Color(0xFFF97316), Color(0xFFFACC15)],
    <Color>[Color(0xFF16A34A), Color(0xFF14B8A6)],
    <Color>[Color(0xFFEF4444), Color(0xFFF43F5E)],
    <Color>[Color(0xFF4F46E5), Color(0xFF8B5CF6)],
  ];

  final FlutterTts _tts = FlutterTts();
  int _index = 0;
  String _voiceLanguage = 'en-US';
  bool _disposed = false;

  String get _capital => _letters[_index];
  String get _small => _capital.toLowerCase();

  @override
  void initState() {
    super.initState();
    unawaited(_prepareVoice());
  }

  Future<void> _selectEnglishLanguage() async {
    for (final candidate in const <String>['en-US', 'en-GB', 'en']) {
      try {
        final dynamic available = await _tts.isLanguageAvailable(candidate);
        if (available == true || available == 1 || available?.toString() == '1') {
          await _tts.setLanguage(candidate);
          _voiceLanguage = candidate;
          return;
        }
      } catch (_) {
        // Older Android/Huawei engines may not support the availability query.
      }
    }
    try {
      await _tts.setLanguage('en-US');
      _voiceLanguage = 'en-US';
    } catch (_) {
      await _tts.setLanguage('en-GB');
      _voiceLanguage = 'en-GB';
    }
  }

  Future<void> _prepareVoice() async {
    try {
      await _selectEnglishLanguage();
      await _tts.setSpeechRate(0.46);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(true);
      await Future<void>.delayed(const Duration(milliseconds: 220));
      await _speak();
    } catch (error) {
      debugPrint('Unable to prepare English card voice: $error');
    }
  }

  double get _volume {
    switch (SoundService.instance.levelNotifier.value) {
      case SoundLevel.high:
      case SoundLevel.medium:
        return 1.0;
      case SoundLevel.low:
        return 0.72;
      case SoundLevel.muted:
        return 0.0;
    }
  }

  Future<void> _speak({Duration delay = Duration.zero}) async {
    if (_disposed || _volume == 0) return;
    if (delay > Duration.zero) await Future<void>.delayed(delay);
    if (_disposed || _volume == 0) return;
    try {
      await _tts.stop();
      await _tts.setLanguage(_voiceLanguage);
      await _tts.setSpeechRate(0.46);
      await _tts.setPitch(1.0);
      await _tts.setVolume(_volume);
      await _tts.speak(_capital);
    } catch (error) {
      debugPrint('Unable to speak $_capital: $error');
      try {
        await _selectEnglishLanguage();
        await _tts.setVolume(_volume);
        await _tts.speak(_capital);
      } catch (retryError) {
        debugPrint('English letter retry failed: $retryError');
      }
    }
  }

  void _go(int delta) {
    setState(() => _index = (_index + delta + _letters.length) % _letters.length);
    SoundService.instance.play('click.wav');
    unawaited(_speak(delay: const Duration(milliseconds: 220)));
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_tts.stop());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _gradients[_index % _gradients.length];
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: const Text('English Letter Cards')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.auto_awesome_rounded, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 7),
                    const Expanded(
                      child: Text('Capital & small letters', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(999)),
                      child: Text('${_index + 1} / ${_letters.length}', style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragEnd: (details) {
                      final velocity = details.primaryVelocity ?? 0;
                      if (velocity.abs() < 180) return;
                      _go(velocity < 0 ? 1 : -1);
                    },
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: Tween<double>(begin: .94, end: 1).animate(animation), child: child),
                      ),
                      child: Container(
                        key: ValueKey<String>(_capital),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(34),
                          gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
                          boxShadow: <BoxShadow>[BoxShadow(color: gradient.first.withAlpha(70), blurRadius: 24, offset: const Offset(0, 10))],
                        ),
                        child: Stack(
                          children: <Widget>[
                            Positioned(top: 18, left: 22, child: Icon(Icons.star_rounded, color: Colors.white.withAlpha(85), size: 52)),
                            Positioned(bottom: 22, right: 20, child: Icon(Icons.circle, color: Colors.white.withAlpha(42), size: 78)),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
                              child: Column(
                                children: <Widget>[
                                  const SizedBox(height: 8),
                                  const Text('CAPITAL LETTER', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                                  Expanded(
                                    child: Center(
                                      child: Text(_capital, style: const TextStyle(color: Colors.white, fontSize: 134, height: .88, fontWeight: FontWeight.w900)),
                                    ),
                                  ),
                                  Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 28), color: Colors.white.withAlpha(105)),
                                  const SizedBox(height: 10),
                                  const Text('small letter', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: .6)),
                                  Expanded(
                                    child: Center(
                                      child: Text(_small, style: TextStyle(color: Colors.white.withAlpha(245), fontSize: 100, height: .9, fontWeight: FontWeight.w800)),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 68,
                  child: FilledButton.icon(
                    onPressed: () => unawaited(_speak()),
                    icon: const Icon(Icons.volume_up_rounded, size: 36),
                    label: Text('Say $_capital', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton.icon(onPressed: () => _go(-1), icon: const Icon(Icons.arrow_back_rounded), label: const Text('Previous')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 54,
                        child: OutlinedButton.icon(onPressed: () => _go(1), icon: const Icon(Icons.arrow_forward_rounded), label: const Text('Next')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text('Swipe left or right to move between letters', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
