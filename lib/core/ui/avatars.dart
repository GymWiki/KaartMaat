import 'package:flutter/material.dart';

/// Number of built-in avatars (assets/avatars/avatar_01.png ...). Players
/// store an index below this.
const avatarCount = 13;

String avatarAsset(int index) {
  final n = (index % avatarCount) + 1;
  return 'assets/avatars/avatar_${n.toString().padLeft(2, '0')}.png';
}

/// A player's avatar: a round picture from the built-in set. Safe for any
/// [index]; it wraps around.
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({super.key, required this.index, this.size = 40});

  final int index;
  final double size;

  @override
  Widget build(BuildContext context) {
    // Decode near the size it is shown at: sharp on the 1080 px share image,
    // light in memory in lists.
    final px = (size * MediaQuery.devicePixelRatioOf(context) * 3)
        .round()
        .clamp(64, 256);
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Image.asset(
          avatarAsset(index),
          width: size,
          height: size,
          cacheWidth: px,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          excludeFromSemantics: true,
          gaplessPlayback: true,
        ),
      ),
    );
  }
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
