import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Number of built-in avatars. Players store an index below this.
const avatarCount = 8;

enum _Ears { none, pointed, round, long, tufts }

enum _Extra { none, hat, glasses, bow, beard, shades }

class _Spec {
  const _Spec(this.background, this.fur, this.ears, this.extra);
  final Color background;
  final Color fur;
  final _Ears ears;
  final _Extra extra;
}

// Original, simple cartoon faces drawn with plain shapes.
const _specs = [
  _Spec(Color(0xFFFFC857), Color(0xFFF4A259), _Ears.pointed, _Extra.none),
  _Spec(Color(0xFF9BC1BC), Color(0xFF8D6A4F), _Ears.round, _Extra.none),
  _Spec(Color(0xFFF2B5D4), Color(0xFFF1F1F1), _Ears.long, _Extra.bow),
  _Spec(Color(0xFFB8B8FF), Color(0xFFC9A66B), _Ears.tufts, _Extra.glasses),
  _Spec(Color(0xFFFF9B71), Color(0xFFE8743B), _Ears.pointed, _Extra.hat),
  _Spec(Color(0xFFA7E8BD), Color(0xFFF7D9B5), _Ears.none, _Extra.hat),
  _Spec(Color(0xFFCDB4DB), Color(0xFFF2C6A0), _Ears.none, _Extra.beard),
  _Spec(Color(0xFF8ECAE6), Color(0xFFD9B38C), _Ears.round, _Extra.shades),
];

/// A player's avatar. Safe for any [index]; it wraps around.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.index, this.size = 40});

  final int index;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(painter: _AvatarPainter(_specs[index % avatarCount])),
      );
}

class _AvatarPainter extends CustomPainter {
  _AvatarPainter(this.spec);
  final _Spec spec;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final c = Offset(s / 2, s / 2);
    final fill = Paint()..style = PaintingStyle.fill;
    final dark = Paint()..color = const Color(0xFF2B2B2B);
    Offset p(double x, double y) => Offset(s * x, s * y);

    canvas.drawCircle(c, s / 2, fill..color = spec.background);
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: c, radius: s / 2)));

    // ears (behind the head)
    fill.color = spec.fur;
    switch (spec.ears) {
      case _Ears.pointed:
        for (final dx in [-1, 1]) {
          canvas.drawPath(
            Path()
              ..moveTo(s * (0.5 + dx * 0.34), s * 0.5)
              ..lineTo(s * (0.5 + dx * 0.28), s * 0.12)
              ..lineTo(s * (0.5 + dx * 0.08), s * 0.34)
              ..close(),
            fill,
          );
        }
      case _Ears.round:
        for (final dx in [-1, 1]) {
          canvas.drawCircle(p(0.5 + dx * 0.28, 0.24), s * 0.11, fill);
        }
      case _Ears.long:
        for (final dx in [-1, 1]) {
          canvas.drawOval(
              Rect.fromCenter(center: p(0.5 + dx * 0.16, 0.14), width: s * 0.14, height: s * 0.34),
              fill);
        }
      case _Ears.tufts:
        for (final dx in [-1, 1]) {
          canvas.drawPath(
            Path()
              ..moveTo(s * (0.5 + dx * 0.3), s * 0.36)
              ..lineTo(s * (0.5 + dx * 0.36), s * 0.14)
              ..lineTo(s * (0.5 + dx * 0.14), s * 0.28)
              ..close(),
            fill,
          );
        }
      case _Ears.none:
        break;
    }

    // head
    canvas.drawCircle(p(0.5, 0.58), s * 0.32, fill..color = spec.fur);

    // eyes and smile
    canvas.drawCircle(p(0.38, 0.52), s * 0.045, dark);
    canvas.drawCircle(p(0.62, 0.52), s * 0.045, dark);
    canvas.drawArc(
      Rect.fromCenter(center: p(0.5, 0.64), width: s * 0.22, height: s * 0.16),
      0.2,
      math.pi - 0.4,
      false,
      Paint()
        ..color = dark.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.03
        ..strokeCap = StrokeCap.round,
    );

    // extras
    switch (spec.extra) {
      case _Extra.hat:
        canvas.drawRect(
            Rect.fromLTWH(s * 0.28, s * 0.18, s * 0.44, s * 0.16), fill..color = const Color(0xFF3D405B));
        canvas.drawRect(
            Rect.fromLTWH(s * 0.2, s * 0.32, s * 0.6, s * 0.05), fill..color = const Color(0xFF3D405B));
      case _Extra.glasses:
        final ring = Paint()
          ..color = dark.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = s * 0.025;
        canvas.drawCircle(p(0.38, 0.52), s * 0.09, ring);
        canvas.drawCircle(p(0.62, 0.52), s * 0.09, ring);
        canvas.drawLine(p(0.47, 0.52), p(0.53, 0.52), ring);
      case _Extra.shades:
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(s * 0.26, s * 0.46, s * 0.48, s * 0.1), Radius.circular(s * 0.04)),
            dark);
      case _Extra.bow:
        final bow = fill..color = const Color(0xFFE63946);
        canvas.drawPath(
            Path()
              ..moveTo(s * 0.5, s * 0.9)
              ..lineTo(s * 0.36, s * 0.82)
              ..lineTo(s * 0.36, s * 0.98)
              ..close()
              ..moveTo(s * 0.5, s * 0.9)
              ..lineTo(s * 0.64, s * 0.82)
              ..lineTo(s * 0.64, s * 0.98)
              ..close(),
            bow);
      case _Extra.beard:
        canvas.drawArc(
            Rect.fromCenter(center: p(0.5, 0.74), width: s * 0.5, height: s * 0.34),
            0,
            math.pi,
            true,
            fill..color = const Color(0xFF6D4C41));
      case _Extra.none:
        break;
    }
  }

  @override
  bool shouldRepaint(_AvatarPainter old) => old.spec != spec;
}

/// Crown for the winner, drawn as a simple vector shape.
class CrownBadge extends StatelessWidget {
  const CrownBadge({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: CustomPaint(painter: _CrownPainter()));
}

class _CrownPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final gold = Paint()..color = const Color(0xFFFFC107);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.08, h * 0.82)
        ..lineTo(w * 0.04, h * 0.28)
        ..lineTo(w * 0.28, h * 0.52)
        ..lineTo(w * 0.5, h * 0.16)
        ..lineTo(w * 0.72, h * 0.52)
        ..lineTo(w * 0.96, h * 0.28)
        ..lineTo(w * 0.92, h * 0.82)
        ..close(),
      gold,
    );
    canvas.drawRect(Rect.fromLTWH(w * 0.08, h * 0.82, w * 0.84, h * 0.1),
        Paint()..color = const Color(0xFFFFA000));
    final jewel = Paint()..color = const Color(0xFFE53935);
    canvas.drawCircle(Offset(w * 0.5, h * 0.66), w * 0.06, jewel);
    for (final x in [0.04, 0.5, 0.96]) {
      canvas.drawCircle(Offset(w * x, h * (x == 0.5 ? 0.14 : 0.26)), w * 0.06, gold);
    }
  }

  @override
  bool shouldRepaint(_CrownPainter old) => false;
}

/// Donkey ("ezel") for last place, drawn as a simple vector shape.
class DonkeyBadge extends StatelessWidget {
  const DonkeyBadge({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: size, height: size, child: CustomPaint(painter: _DonkeyPainter()));
}

class _DonkeyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final grey = Paint()..color = const Color(0xFF9E9E9E);
    final dark = Paint()..color = const Color(0xFF616161);
    // long ears
    for (final dx in [-1, 1]) {
      canvas.save();
      canvas.translate(w * (0.5 + dx * 0.2), h * 0.28);
      canvas.rotate(dx * 0.35);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * 0.2, height: h * 0.5), grey);
      canvas.restore();
    }
    // head and muzzle
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.5, h * 0.55), width: w * 0.6, height: h * 0.55), grey);
    canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.74), width: w * 0.42, height: h * 0.28),
        Paint()..color = const Color(0xFFE0D6C8));
    canvas.drawCircle(Offset(w * 0.42, h * 0.76), w * 0.035, dark);
    canvas.drawCircle(Offset(w * 0.58, h * 0.76), w * 0.035, dark);
    // eyes
    canvas.drawCircle(Offset(w * 0.38, h * 0.5), w * 0.045, Paint()..color = const Color(0xFF212121));
    canvas.drawCircle(Offset(w * 0.62, h * 0.5), w * 0.045, Paint()..color = const Color(0xFF212121));
    // mane
    canvas.drawRect(Rect.fromLTWH(w * 0.46, h * 0.26, w * 0.08, h * 0.12), dark);
  }

  @override
  bool shouldRepaint(_DonkeyPainter old) => false;
}

/// Grid to pick one of the built-in avatars.
Future<int?> pickAvatar(BuildContext context, {required int current}) =>
    showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: [
              for (var i = 0; i < avatarCount; i++)
                InkResponse(
                  radius: 40,
                  onTap: () => Navigator.pop(context, i),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 3,
                        color: i == current % avatarCount
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                      ),
                    ),
                    child: PlayerAvatar(index: i, size: 64),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
