import 'package:flutter/material.dart';

enum MascotMood { happy, calm }

class StarMascot extends StatelessWidget {
  const StarMascot({super.key, this.size = 88, this.mood = MascotMood.happy});
  final double size;
  final MascotMood mood;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFFFF7D6)),
      child: Icon(mood == MascotMood.happy ? Icons.star_rounded : Icons.emoji_emotions_rounded, color: const Color(0xFFFFC857), size: size * 0.72),
    );
  }
}
