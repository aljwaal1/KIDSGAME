import 'dart:math';

import 'package:flutter/material.dart';

import '../services/score_service.dart';
import '../services/sound_service.dart';

class ShapeShadowPage extends StatefulWidget {
  const ShapeShadowPage({super.key});

  @override
  State<ShapeShadowPage> createState() => _ShapeShadowPageState();
}

class _ShapeShadowPageState extends State<ShapeShadowPage> {
  final Random _random = Random();
  int _score = 0;
  late IconData _target;
  late List<IconData> _choices;
  String _message = 'اختر ظل الشكل الصحيح';

  static const List<IconData> _icons = [
    Icons.star_rounded,
    Icons.favorite_rounded,
    Icons.home_rounded,
    Icons.directions_car_rounded,
    Icons.pets_rounded,
    Icons.flight_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  void _newRound() {
    final target = _icons[_random.nextInt(_icons.length)];
    final wrong = List<IconData>.from(_icons.where((item) => item != target));
    wrong.shuffle(_random);
    final choices = <IconData>[target, wrong[0], wrong[1], wrong[2]]..shuffle(_random);
    setState(() {
      _target = target;
      _choices = choices;
      _message = 'اختر ظل الشكل الصحيح';
    });
  }

  void _pick(IconData icon) {
    if (icon == _target) {
      SoundService.instance.play('win.wav');
      ScoreService.instance.addStars(1);
      setState(() {
        _score++;
        _message = 'إجابة صحيحة 🎉';
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _newRound();
      });
    } else {
      SoundService.instance.play('wrong.wav');
      setState(() => _message = 'انظر للشكل جيدًا');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ظل الشكل')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(_message, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'Changa')),
                const SizedBox(height: 12),
                Icon(_target, size: 90, color: const Color(0xFFF97316)),
                const SizedBox(height: 8),
                Text('النقاط: $_score', style: const TextStyle(color: Color(0xFF64748B))),
              ],
            ),
          ),
          const SizedBox(height: 18),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _choices.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemBuilder: (context, index) {
              final icon = _choices[index];
              return InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => _pick(icon),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, size: 76, color: const Color(0xFF334155).withOpacity(0.45)),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
