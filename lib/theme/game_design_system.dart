import 'package:flutter/material.dart';

@immutable
class GamePalette {
  const GamePalette({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.surface,
    required this.ink,
  });

  final Color primary;
  final Color secondary;
  final Color accent;
  final Color background;
  final Color surface;
  final Color ink;

  LinearGradient get heroGradient => LinearGradient(
        colors: <Color>[primary, secondary],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      );
}

abstract final class GamePalettes {
  static const GamePalette sports = GamePalette(
    primary: Color(0xFF075985), secondary: Color(0xFF0891B2), accent: Color(0xFFFBBF24),
    background: Color(0xFFF0F9FF), surface: Colors.white, ink: Color(0xFF0C4A6E),
  );
  static const GamePalette field = GamePalette(
    primary: Color(0xFF047857), secondary: Color(0xFF0D9488), accent: Color(0xFFFBBF24),
    background: Color(0xFFF0FDF4), surface: Colors.white, ink: Color(0xFF064E3B),
  );
  static const GamePalette strategy = GamePalette(
    primary: Color(0xFF4338CA), secondary: Color(0xFF7C3AED), accent: Color(0xFFF59E0B),
    background: Color(0xFFF5F3FF), surface: Colors.white, ink: Color(0xFF312E81),
  );
  static const GamePalette traditional = GamePalette(
    primary: Color(0xFF92400E), secondary: Color(0xFFD97706), accent: Color(0xFF0F766E),
    background: Color(0xFFFFFBEB), surface: Color(0xFFFFFDF7), ink: Color(0xFF78350F),
  );
  static const GamePalette puzzle = GamePalette(
    primary: Color(0xFF6D28D9), secondary: Color(0xFFDB2777), accent: Color(0xFF06B6D4),
    background: Color(0xFFFAF5FF), surface: Colors.white, ink: Color(0xFF4C1D95),
  );
  static const GamePalette reasoning = GamePalette(
    primary: Color(0xFF0369A1), secondary: Color(0xFF4F46E5), accent: Color(0xFFF97316),
    background: Color(0xFFF0F9FF), surface: Colors.white, ink: Color(0xFF1E3A8A),
  );
  static const GamePalette learning = GamePalette(
    primary: Color(0xFF7C3AED), secondary: Color(0xFFEC4899), accent: Color(0xFFFBBF24),
    background: Color(0xFFFFF7ED), surface: Colors.white, ink: Color(0xFF581C87),
  );
  static const GamePalette memory = GamePalette(
    primary: Color(0xFFBE185D), secondary: Color(0xFF7C3AED), accent: Color(0xFF14B8A6),
    background: Color(0xFFFDF2F8), surface: Colors.white, ink: Color(0xFF831843),
  );
}

class GameBackdrop extends StatelessWidget {
  const GameBackdrop({super.key, required this.palette, required this.child});

  final GamePalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[palette.background, Color.lerp(palette.background, palette.secondary, .08)!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            IgnorePointer(child: CustomPaint(painter: _BackdropPainter(palette))),
            child,
          ],
        ),
      );
}

class GameHeroPanel extends StatelessWidget {
  const GameHeroPanel({
    super.key,
    required this.palette,
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
  });

  final GamePalette palette;
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: 88),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        decoration: BoxDecoration(
          gradient: palette.heroGradient,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: Colors.white.withAlpha(80)),
          boxShadow: <BoxShadow>[BoxShadow(color: palette.primary.withAlpha(55), blurRadius: 22, offset: const Offset(0, 10))],
        ),
        child: Row(children: <Widget>[
          if (icon != null) ...<Widget>[
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(color: Colors.white.withAlpha(42), borderRadius: BorderRadius.circular(17)),
              child: Icon(icon, color: Colors.white, size: 30),
            ),
            const SizedBox(width: 13),
          ],
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: <Widget>[
              Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 20, height: 1.25, fontWeight: FontWeight.w900)),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: 4),
                Text(subtitle!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 12.5, fontWeight: FontWeight.w700)),
              ],
            ]),
          ),
          if (trailing != null) ...<Widget>[const SizedBox(width: 10), trailing!],
        ]),
      );
}

class GameSurface extends StatelessWidget {
  const GameSurface({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color, this.radius = 24});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withAlpha(150)),
          boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x120F172A), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: child,
      );
}

class GameBadge extends StatelessWidget {
  const GameBadge({super.key, required this.label, required this.color, this.icon});

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        constraints: const BoxConstraints(minHeight: kMinInteractiveDimension),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(color: color.withAlpha(24), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withAlpha(110))),
        child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
          if (icon != null) ...<Widget>[Icon(icon, color: color, size: 19), const SizedBox(width: 6)],
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900)),
        ]),
      );
}

class _BackdropPainter extends CustomPainter {
  const _BackdropPainter(this.palette);
  final GamePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = palette.primary.withAlpha(10);
    canvas.drawCircle(Offset(size.width * .08, size.height * .15), size.width * .22, paint);
    canvas.drawCircle(Offset(size.width * .94, size.height * .48), size.width * .28, paint..color = palette.secondary.withAlpha(9));
    canvas.drawCircle(Offset(size.width * .18, size.height * .9), size.width * .18, paint..color = palette.accent.withAlpha(8));
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter oldDelegate) => oldDelegate.palette != palette;
}
