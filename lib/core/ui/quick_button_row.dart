import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import 'touch.dart';

/// Number buttons (for example 0..N) that wrap onto more rows instead of
/// scrolling sideways, so every value is one tap away and nothing hides.
/// Each button is at least [buttonSize] wide and tall; a row is filled evenly.
///
/// [disabled] values are greyed out, struck through and not tappable (for
/// example the bid the dealer may not make).
class QuickButtonRow extends StatelessWidget {
  const QuickButtonRow({
    super.key,
    required this.values,
    required this.onSelected,
    this.selected,
    this.disabled = const {},
    this.labelOf,
    this.buttonSize = kTouchTarget,
    this.gap = kTouchGap,
  });

  final List<int> values;
  final ValueChanged<int> onSelected;
  final int? selected;
  final Set<int> disabled;
  final String Function(int value)? labelOf;
  final double buttonSize;

  /// Space between buttons.
  final double gap;

  /// Buttons per row for a given width. Public for tests.
  static int perRow(double width, double buttonSize, [double gap = kTouchGap]) =>
      math.max(1, ((width + gap) / (buttonSize + gap)).floor());

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(builder: (context, constraints) {
      final per = perRow(constraints.maxWidth, buttonSize, gap);
      final width = (constraints.maxWidth - gap * (per - 1)) / per;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final v in values)
            Builder(builder: (context) {
              final isSelected = v == selected;
              final isDisabled = disabled.contains(v);
              final label = labelOf?.call(v) ?? '$v';
              return Semantics(
                button: true,
                enabled: !isDisabled,
                selected: isSelected,
                label: isDisabled ? '$label, ${l10n.notAllowed}' : label,
                excludeSemantics: true,
                child: SizedBox(
                  width: width,
                  height: buttonSize,
                  child: Material(
                    color: isSelected
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? scheme.primary : scheme.outlineVariant,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: isDisabled ? null : () => onSelected(v),
                      child: Center(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontFamily: AppTheme.numeralFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                            color: isDisabled
                                ? scheme.onSurface.withValues(alpha: 0.38)
                                : isSelected
                                    ? AppTheme.ink
                                    : scheme.onSurface,
                            decoration:
                                isDisabled ? TextDecoration.lineThrough : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      );
    });
  }
}
