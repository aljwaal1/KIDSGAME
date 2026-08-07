import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../services/sound_service.dart';

class ArabicLetterCardsPage extends StatefulWidget {
  const ArabicLetterCardsPage({super.key});

  @override
  State<ArabicLetterCardsPage> createState() => _ArabicLetterCardsPageState();
}

class _ArabicLetterCardsPageState extends State<ArabicLetterCardsPage> {
  static const List<String> _letters = <String>[
    'أ','ب','ت','ث','ج','ح','خ','د','ذ','ر','ز','س','ش','ص','ض','ط','ظ','ع','غ','ف','ق','ك','ل','م','ن','ه','و','ي',
  ];

  static const Map<String, String> _names = <String, String>{
    'أ': 'أَلِف', 'ب': 'بَاء', 'ت': 'تَاء', 'ث': 'ثَاء', 'ج': 'جِيم',
    'ح': 'حَاء', 'خ': 'خَاء', 'د': 'دَال', 'ذ': 'ذَال', 'ر': 'رَاء',
    'ز': 'زَاي', 'س': 'سِين', 'ش': 'شِين', 'ص': 'صَاد', 'ض': 'ضَاد',
    'ط': 'طَاء', 'ظ': 'ظَاء', 'ع': 'عَيْن', 'غ': 'غَيْن', 'ف': 'فَاء',
    'ق': 'قَاف', 'ك': 'كَاف', 'ل': 'لَام', 'م': 'مِيم', 'ن': 'نُون',
    'ه': 'هَاء', 'و': 'وَاو', 'ي': 'يَاء',
  };

  static const List<List<Color>> _gradients = <List<Color>>[
    <Color>[Color(0xFF7C3AED), Color(0xFFEC4899)],
    <Color>[Color(0xFF06B6D4), Color(0xFF3B82F6)],
    <Color>[Color(0xFF22C55E), Color(0xFF14B8A6)],
    <Color>[Color(0xFFF97316), Color(0xFFFACC15)],
    <Color>[Color(0xFFEF4444), Color(0xFFFB7185)],
    <Color>[Color(0xFF8B5CF6), Color(0xFF6366F1)],
  ];

  final FlutterTts _tts = FlutterTts();
  int _index = 0;
  String _voiceLanguage = 'ar-SA';
  double _dragStartX = 0;
  bool _disposed = false;

  String get _letter => _letters[_index];
  String get _name => _names[_letter] ?? _letter;

  @override
  void initState() {
    super.initState();
    unawaited(_prepareVoice());
  }

  Future<void> _prepareVoice() async {
    try {
      final dynamic rawLanguages = await _tts.getLanguages;
      final languages = rawLanguages is List
          ? rawLanguages.map((value) => value.toString()).toList()
          : const <String>[];
      _voiceLanguage = <String>['ar-SA', 'ar', 'ar-EG', 'ar-AE'].firstWhere(
        (candidate) => languages.any((available) => available.toLowerCase() == candidate.toLowerCase()),
        orElse: () => 'ar-SA',
      );
      await _tts.setLanguage(_voiceLanguage);
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);
      await Future<void>.delayed(const Duration(milliseconds: 180));
      await _speak();
    } catch (error) {
      debugPrint('تعذر إعداد صوت بطاقات العربية: $error');
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

  Future<void> _speak() async {
    if (_disposed || _volume == 0) return;
    try {
      await _tts.stop();
      await _tts.setLanguage(_voiceLanguage);
      await _tts.setSpeechRate(0.48);
      await _tts.setPitch(1.0);
      await _tts.setVolume(_volume);
      await _tts.speak(_name);
    } catch (error) {
      debugPrint('تعذر نطق $_name: $error');
    }
  }

  void _go(int delta) {
    setState(() => _index = (_index + delta + _letters.length) % _letters.length);
    SoundService.instance.play('click.wav');
    unawaited(Future<void>.delayed(const Duration(milliseconds: 100), _speak));
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
    return Scaffold(
      appBar: AppBar(title: const Text('بطاقات الحروف العربية')),
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
                    child: Text('تعلّم الحروف باللمس والصوت', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, fontFamily: 'Changa')),
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
                  onHorizontalDragStart: (details) => _dragStartX = details.localPosition.dx,
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
                      key: ValueKey<String>(_letter),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(34),
                        gradient: LinearGradient(colors: gradient, begin: Alignment.topRight, end: Alignment.bottomLeft),
                        boxShadow: <BoxShadow>[BoxShadow(color: gradient.first.withAlpha(70), blurRadius: 24, offset: const Offset(0, 10))],
                      ),
                      child: Stack(
                        children: <Widget>[
                          Positioned(top: 20, right: 22, child: Icon(Icons.star_rounded, color: Colors.white.withAlpha(85), size: 50)),
                          Positioned(bottom: 28, left: 24, child: Icon(Icons.circle, color: Colors.white.withAlpha(45), size: 70)),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(_letter, style: const TextStyle(color: Colors.white, fontSize: 185, height: .88, fontWeight: FontWeight.w900, fontFamily: 'Cairo')),
                                const SizedBox(height: 18),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
                                  decoration: BoxDecoration(color: Colors.white.withAlpha(45), borderRadius: BorderRadius.circular(999), border: Border.all(color: Colors.white.withAlpha(90))),
                                  child: Text(_name, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, fontFamily: 'Changa')),
                                ),
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
                height: 64,
                child: FilledButton.icon(
                  onPressed: () => unawaited(_speak()),
                  icon: const Icon(Icons.volume_up_rounded, size: 34),
                  label: Text('استمع إلى $_name', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, fontFamily: 'Changa')),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton.icon(onPressed: () => _go(-1), icon: const Icon(Icons.arrow_forward_rounded), label: const Text('السابق')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton.icon(onPressed: () => _go(1), icon: const Icon(Icons.arrow_back_rounded), label: const Text('التالي')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              const Text('يمكنك أيضًا السحب يمينًا أو يسارًا للتنقل', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
