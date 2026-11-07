import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import 'touch.dart';

class PreviewScore {
  const PreviewScore(this.label, this.points);
  final String label;
  final int points;
}

/// What this round will score, shown before the player confirms. Wraps to a
/// second row for more than four participants (no sideways scrolling).
///
/// [badges] are short markers such as "NAT" or "PIT". [sum] shows the
/// zero-sum check for games where the points must add up to zero. When
/// [message] is set (why the input is not complete or not allowed) it is
/// shown instead of the scores.
class LiveScorePreview extends StatelessWidget {
  const LiveScorePreview({
    super.key,
    required this.scores,
    this.badges = const [],
    this.sum,
    this.message,
  });

  final List<PreviewScore> scores;
  final List<String> badges;
  final int? sum;
  final String? message;

  static String signed(int points) => points > 0 ? '+$points' : '$points';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    if (message != null) {
      return Container(
        constraints: const BoxConstraints(minHeight: kTouchTarget),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Semantics(
          liveRegion: true,
          child: Text(message!, style: TextStyle(color: scheme.error, fontSize: 15)),
        ),
      );
    }

    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(builder: (context, constraints) {
            final per = math.max(1, math.min(4, scores.length));
            final width = (constraints.maxWidth - kTouchGap * (per - 1)) / per;
            return Wrap(
              spacing: kTouchGap,
              runSpacing: 4,
              children: [
                for (final s in scores)
                  SizedBox(
                    width: width,
                    child: Column(
                      children: [
                        Text(
                          s.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                        // The sign is part of the text, so a loss is not
                        // only shown by color.
                        Text(
                          signed(s.points),
                          style: TextStyle(
                            fontFamily: AppTheme.numeralFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 26,
                            height: 1.1,
                            color: s.points < 0 ? scheme.error : scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }),
          if (badges.isNotEmpty || sum != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final b in badges)
                    Chip(
                      label: Text(b, style: const TextStyle(fontWeight: FontWeight.w700)),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: scheme.tertiaryContainer,
                      side: BorderSide.none,
                    ),
                  if (sum != null)
                    Text(l10n.zeroSum(sum!),
                        style: TextStyle(
                            fontSize: 13,
                            color: sum == 0 ? scheme.onSurfaceVariant : scheme.error)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
