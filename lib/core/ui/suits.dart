import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum Suit { spades, hearts, clubs, diamonds }

Suit suitAt(int index) => Suit.values[index % Suit.values.length];

/// A card suit drawn with plain vector shapes (no font or emoji involved).
/// Hearts and diamonds are red, spades and clubs follow the text color.
class SuitPip extends StatelessWidget {
  const SuitPip(this.suit, {super.key, this.size = 18, this.color});

  final Suit suit;
  final double size;

  /// Overrides the default (red or text color).
  final Color? color;

  bool get isRed => suit == Suit.hearts || suit == Suit.diamonds;

  @override
  Widget build(BuildContext context) {
    final c = color ??
        (isRed
            ? (Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFFFF8A7A)
                : AppTheme.suitRed)
            : Theme.of(context).colorScheme.onSurface);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _SuitPainter(suit, c)),
    );
  }
}

class _SuitPainter extends CustomPainter {
  _SuitPainter(this.suit, this.color);
  final Suit suit;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final paint = Paint()..color = color;

    Path heart(double top, double bottom) {
      final p = Path()
        ..moveTo(w * 0.5, bottom)
        ..cubicTo(w * 0.05, h * 0.62, w * 0.0, top + h * 0.18, w * 0.25, top + h * 0.08)
        ..cubicTo(w * 0.4, top, w * 0.5, top + h * 0.12, w * 0.5, top + h * 0.2)
        ..cubicTo(w * 0.5, top + h * 0.12, w * 0.6, top, w * 0.75, top + h * 0.08)
        ..cubicTo(w * 1.0, top + h * 0.18, w * 0.95, h * 0.62, w * 0.5, bottom)
        ..close();
      return p;
    }

    switch (suit) {
      case Suit.hearts:
        canvas.drawPath(heart(h * 0.08, h * 0.94), paint);
      case Suit.diamonds:
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.5, h * 0.04)
            ..lineTo(w * 0.88, h * 0.5)
            ..lineTo(w * 0.5, h * 0.96)
            ..lineTo(w * 0.12, h * 0.5)
            ..close(),
          paint,
        );
      case Suit.spades:
        canvas.save();
        canvas.translate(0, h);
        canvas.scale(1, -1);
        canvas.drawPath(heart(h * 0.2, h * 0.98), paint);
        canvas.restore();
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.5, h * 0.55)
            ..lineTo(w * 0.62, h * 0.96)
            ..lineTo(w * 0.38, h * 0.96)
            ..close(),
          paint,
        );
      case Suit.clubs:
        canvas.drawCircle(Offset(w * 0.5, h * 0.28), w * 0.22, paint);
        canvas.drawCircle(Offset(w * 0.27, h * 0.56), w * 0.22, paint);
        canvas.drawCircle(Offset(w * 0.73, h * 0.56), w * 0.22, paint);
        canvas.drawPath(
          Path()
            ..moveTo(w * 0.5, h * 0.45)
            ..lineTo(w * 0.62, h * 0.96)
            ..lineTo(w * 0.38, h * 0.96)
            ..close(),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(_SuitPainter old) => old.suit != suit || old.color != color;
}

/// Rank above a suit, like the corner index of a playing card.
class CornerIndex extends StatelessWidget {
  const CornerIndex({super.key, required this.rank, required this.suit, this.highlight = false});

  final int rank;
  final Suit suit;

  /// Gold rank, used for first place.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 34,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$rank',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  height: 1,
                  color: highlight ? scheme.tertiary : scheme.onSurface,
                ),
          ),
          const SizedBox(height: 4),
          SuitPip(suit, size: 16),
        ],
      ),
    );
  }
}
