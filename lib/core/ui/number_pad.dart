import 'package:flutter/material.dart';

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

/// Large 3x4 keypad for one-thumb number entry at the table.
class NumberPad extends StatelessWidget {
  const NumberPad({super.key, required this.onKey, this.allowNegative = true});

  final void Function(String key) onKey;
  final bool allowNegative;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['±', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final row in _rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                for (final key in row)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: SizedBox(
                        height: 56,
                        child: FilledButton.tonal(
                          onPressed:
                              key == '±' && !allowNegative ? null : () => onKey(key),
                          style: FilledButton.styleFrom(
                              textStyle: const TextStyle(fontSize: 24)),
                          child: key == '⌫'
                              ? const Icon(Icons.backspace_outlined)
                              : Text(key),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
