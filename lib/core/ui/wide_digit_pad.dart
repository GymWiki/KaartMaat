import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'touch.dart';

/// Digits 0-9 in two rows of six keys (1-5 and ⌫, 6-9, 0 and C), only 2 key
/// rows high. For non-negative numbers where a normal pad would not fit
/// under a game's input panel. Keys are '0'-'9', '⌫' (backspace) and 'C'
/// (clear), and are at least [kTouchTarget] wide on a normal phone.
class WideDigitPad extends StatelessWidget {
  const WideDigitPad({super.key, required this.onKey, this.keyHeight = kTouchTarget});

  final void Function(String key) onKey;
  final double keyHeight;

  static const _rows = [
    ['1', '2', '3', '4', '5', '⌫'],
    ['6', '7', '8', '9', '0', 'C'],
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String? semantic(String key) => switch (key) {
          '⌫' => l10n.padBackspace,
          'C' => l10n.padClear,
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
                for (var c = 0; c < _rows[r].length; c++) ...[
                  if (c > 0) const SizedBox(width: kTouchGap),
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: semantic(_rows[r][c]),
                      excludeSemantics: semantic(_rows[r][c]) != null,
                      child: SizedBox(
                        height: keyHeight,
                        child: FilledButton.tonal(
                          onPressed: () => onKey(_rows[r][c]),
                          style: FilledButton.styleFrom(
                            minimumSize: Size(0, keyHeight),
                            padding: EdgeInsets.zero,
                            textStyle: const TextStyle(fontSize: 22),
                          ),
                          child: switch (_rows[r][c]) {
                            '⌫' => const Icon(Icons.backspace_outlined),
                            'C' => const Icon(Icons.clear),
                            final digit => Text(digit),
                          },
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
