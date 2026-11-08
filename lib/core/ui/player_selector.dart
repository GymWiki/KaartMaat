import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import 'touch.dart';

class PlayerChipData {
  const PlayerChipData({
    required this.label,
    this.value,
    this.done = false,
    this.caption,
    this.highlight = false,
    this.error = false,
  });

  final String label;

  /// What has been entered for this player, shown big under the name.
  final String? value;

  /// Entered or derived; shown with a check so it does not rely on color.
  final bool done;

  /// Small third line (for example the new running total).
  final String? caption;

  /// Marks the chip with an accent border (for example: reaches the target).
  final bool highlight;

  /// Marks the chip as holding an unacceptable value.
  final bool error;
}

/// Row of players (wrapping, never scrolling) to pick whose value is being
/// entered. Use [nextUnfilled] to move on after a value is set.
class PlayerSelector extends StatelessWidget {
  const PlayerSelector({
    super.key,
    required this.chips,
    required this.selectedIndex,
    required this.onSelected,
    this.perRow = 4,
  });

  final List<PlayerChipData> chips;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Most chips on one row; more players wrap to a second row.
  final int perRow;

  /// The next player after [from] (cyclic) that still has no value. Null when
  /// everybody is filled in. A derived (auto-completed) player counts as
  /// filled and is skipped.
  static int? nextUnfilled(List<bool> filled, int from) {
    for (var step = 1; step <= filled.length; step++) {
      final i = (from + step) % filled.length;
      if (!filled[i]) return i;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;

    return LayoutBuilder(
      builder: (context, constraints) {
        final per = math.max(1, math.min(perRow, chips.length));
        final width = (constraints.maxWidth - kTouchGap * (per - 1)) / per;
        return Wrap(
          spacing: kTouchGap,
          runSpacing: kTouchGap,
          children: [
            for (var i = 0; i < chips.length; i++)
              Semantics(
                button: true,
                selected: i == selectedIndex,
                label: [
                  chips[i].label,
                  if (chips[i].value != null) chips[i].value!,
                  if (chips[i].caption != null) chips[i].caption!,
                  if (chips[i].done) l10n.entered,
                ].join(', '),
                excludeSemantics: true,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: width,
                    maxWidth: width,
                    minHeight: kTouchTarget,
                  ),
                  child: Material(
                    color: i == selectedIndex
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: chips[i].error
                            ? scheme.error
                            : chips[i].highlight
                            ? scheme.tertiary
                            : i == selectedIndex
                            ? scheme.primary
                            : scheme.outlineVariant,
                        width: chips[i].error || chips[i].highlight ? 2.5 : 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onSelected(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              chips[i].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: i == selectedIndex
                                    ? AppTheme.ink
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (chips[i].done)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 4),
                                    child: Icon(
                                      Icons.check,
                                      size: 14,
                                      color: i == selectedIndex
                                          ? AppTheme.ink
                                          : scheme.secondary,
                                    ),
                                  ),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      chips[i].value ?? '–',
                                      style: TextStyle(
                                        fontFamily: AppTheme.numeralFont,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 22,
                                        height: 1.1,
                                        color: i == selectedIndex
                                            ? AppTheme.ink
                                            : scheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (chips[i].caption != null)
                              Text(
                                chips[i].caption!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1.1,
                                  fontWeight: chips[i].highlight
                                      ? FontWeight.w800
                                      : null,
                                  color: chips[i].error
                                      ? scheme.error
                                      : i == selectedIndex
                                      ? AppTheme.ink
                                      : scheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
