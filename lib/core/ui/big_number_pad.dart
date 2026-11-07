import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'touch.dart';

/// Applies one keypad key to the text typed so far. Pure, so it is testable.
/// Keys: '0'-'9', '±' (toggle sign), '⌫' (backspace).
String applyKey(String current, String key, {int maxDigits = 6}) {
  switch (key) {
    case '⌫':
      return current.isEmpty ? current : current.substring(0, current.length - 1);
    case '±':
      if (current.isEmpty || current == '-') return current == '-' ? '' : '-';
      return current.startsWith('-') ? current.substring(1) : '-$current';
    default:
      final digits = current.replaceAll('-', '');
      if (digits.length >= maxDigits) return current;
      // No leading zeros: "0" followed by a digit replaces the zero.
      if (digits == '0') return '${current.startsWith('-') ? '-' : ''}$key';
      return '$current$key';
  }
}

/// Large 3x4 keypad for one-thumb number entry, no system keyboard.
/// Keys are [keyHeight] tall (at least [kTouchTarget] by default) with a gap
/// between them.
class BigNumberPad extends StatelessWidget {
  const BigNumberPad({
    super.key,
    required this.onKey,
    this.allowNegative = true,
    this.keyHeight = kTouchTarget,
  });

  final void Function(String key) onKey;
  final bool allowNegative;
  final double keyHeight;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['±', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String? semantic(String key) => switch (key) {
          '⌫' => l10n.padBackspace,
          '±' => l10n.padSign,
          _ => null,
        };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var r = 0; r < _rows.length; r++)
          Padding(
            padding: EdgeInsets.only(bottom: r == _rows.length - 1 ? 0 : kTouchGap),
            child: Row(
              children: [
                for (var c = 0; c < 3; c++) ...[
                  if (c > 0) const SizedBox(width: kTouchGap),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: semantic(_rows[r][c]),
                      excludeSemantics: semantic(_rows[r][c]) != null,
                      child: SizedBox(
                        height: keyHeight,
                        child: FilledButton.tonal(
                          onPressed: _rows[r][c] == '±' && !allowNegative
                              ? null
                              : () => onKey(_rows[r][c]),
                          style: FilledButton.styleFrom(
                            minimumSize: Size(0, keyHeight),
                            padding: EdgeInsets.zero,
                            textStyle: const TextStyle(fontSize: 24),
                          ),
                          child: _rows[r][c] == '⌫'
                              ? const Icon(Icons.backspace_outlined)
                              : Text(_rows[r][c]),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
