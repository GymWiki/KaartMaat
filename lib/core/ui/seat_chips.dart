import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';

/// What a seat is marked with in a round: the dealer, or the first player to
/// bid (left of the dealer).
enum SeatMarker { dealer, firstBidder }

/// Small round brass chip with a dark "D": the dealer. The letter, not the
/// colour, carries the meaning.
class DealerChip extends StatelessWidget {
  const DealerChip({super.key, this.size = 16});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.dealerSemantics,
    excludeSemantics: true,
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.brass,
      ),
      child: Text(
        'D',
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontFamily: AppTheme.numeralFont,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.68,
          height: 1,
          color: AppTheme.ink,
        ),
      ),
    ),
  );
}

/// Outlined round chip with a "1": the first to bid.
class FirstBidderChip extends StatelessWidget {
  const FirstBidderChip({super.key, this.size = 16});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.l10n.firstBidderSemantics,
    excludeSemantics: true,
    child: Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.brass, width: 1.5),
      ),
      child: Text(
        '1',
        textScaler: TextScaler.noScaling,
        style: TextStyle(
          fontFamily: AppTheme.numeralFont,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.68,
          height: 1,
          color: AppTheme.brass,
        ),
      ),
    ),
  );
}

/// A name with the seat marker next to it. The name shrinks with an ellipsis
/// before the chip ever does, so long names and 7 or 8 players still fit. When
/// the marker changes (a new round) the chip pops in and out in about 250 ms,
/// unless the system asks for reduced motion.
class NameWithMarker extends StatelessWidget {
  const NameWithMarker({
    super.key,
    required this.name,
    required this.marker,
    required this.style,
    this.chipSize = 16,
    this.textAlign = TextAlign.center,
  });

  final String name;
  final SeatMarker? marker;
  final TextStyle? style;
  final double chipSize;
  final TextAlign textAlign;

  static const duration = Duration(milliseconds: 250);

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    final chip = switch (marker) {
      SeatMarker.dealer => DealerChip(
        key: const ValueKey('dealer'),
        size: chipSize,
      ),
      SeatMarker.firstBidder => FirstBidderChip(
        key: const ValueKey('first'),
        size: chipSize,
      ),
      null => const SizedBox.shrink(key: ValueKey('none')),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: textAlign,
            style: style,
          ),
        ),
        AnimatedSwitcher(
          duration: reduce ? Duration.zero : duration,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: marker == null
              ? chip
              : Padding(
                  key: ValueKey(marker),
                  padding: const EdgeInsets.only(left: 4),
                  child: chip,
                ),
        ),
      ],
    );
  }
}
