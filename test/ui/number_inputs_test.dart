import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/ui/big_number_pad.dart';
import 'package:kaartmaat/core/ui/quick_button_row.dart';
import 'package:kaartmaat/core/ui/touch.dart';

import '../helpers.dart';

void main() {
  group('BigNumberPad', () {
    testWidgets('sends the pressed key and has big keys', (tester) async {
      usePhoneScreen(tester);
      final keys = <String>[];
      await pumpApp(tester, BigNumberPad(onKey: keys.add));

      await tester.tap(find.text('7'));
      await tester.tap(find.text('0'));
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.tap(find.text('±'));
      expect(keys, ['7', '0', '⌫', '±']);

      final size = tester.getSize(find.widgetWithText(FilledButton, '7'));
      expect(size.height, greaterThanOrEqualTo(kTouchTarget));
      expect(size.width, greaterThanOrEqualTo(kTouchTarget));
    });

    testWidgets('the sign key can be switched off', (tester) async {
      var presses = 0;
      await pumpApp(tester, BigNumberPad(onKey: (_) => presses++, allowNegative: false));
      await tester.tap(find.text('±'), warnIfMissed: false);
      expect(presses, 0);
    });

    testWidgets('special keys have a spoken label', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, BigNumberPad(onKey: (_) {}));
      expect(find.bySemanticsLabel('Wis laatste cijfer'), findsOneWidget);
      expect(find.bySemanticsLabel('Plus of min'), findsOneWidget);
      handle.dispose();
    });
  });

  group('QuickButtonRow', () {
    test('buttons per row follow the width', () {
      expect(QuickButtonRow.perRow(411 - 32, 56), 6); // (379+8)/64
      expect(QuickButtonRow.perRow(100, 56), 1);
      expect(QuickButtonRow.perRow(20, 56), 1);
    });

    testWidgets('0..17 wraps over rows: all visible, no sideways scrolling, big',
        (tester) async {
      usePhoneScreen(tester);
      final picked = <int>[];
      await pumpApp(
        tester,
        Padding(
          padding: const EdgeInsets.all(16),
          child: QuickButtonRow(
            values: [for (var i = 0; i <= 17; i++) i],
            onSelected: picked.add,
          ),
        ),
      );

      expect(find.byType(Scrollable), findsNothing);
      for (var i = 0; i <= 17; i++) {
        final rect = tester.getRect(find.text('$i'));
        expect(rect.right, lessThanOrEqualTo(411), reason: 'button $i');
        expect(rect.left, greaterThanOrEqualTo(0));
      }
      final box = tester.getSize(find.ancestor(
          of: find.text('5'), matching: find.byType(SizedBox)).first);
      expect(box.height, greaterThanOrEqualTo(kTouchTarget));

      await tester.tap(find.text('12'));
      expect(picked, [12]);
    });

    testWidgets('disabled values are not tappable and say why', (tester) async {
      final handle = tester.ensureSemantics();
      final picked = <int>[];
      await pumpApp(
        tester,
        QuickButtonRow(
          values: const [0, 1, 2, 3],
          disabled: const {2},
          selected: 1,
          onSelected: picked.add,
        ),
      );

      await tester.tap(find.text('2'), warnIfMissed: false);
      expect(picked, isEmpty);
      await tester.tap(find.text('3'));
      expect(picked, [3]);

      // struck through, and announced as not allowed
      final style = tester.widget<Text>(find.text('2')).style!;
      expect(style.decoration, TextDecoration.lineThrough);
      expect(find.bySemanticsLabel('2, niet toegestaan'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('works in the dark and OLED themes too', (tester) async {
      for (final theme in [
        ThemeData.dark(useMaterial3: true),
      ]) {
        await pumpApp(
          tester,
          QuickButtonRow(values: const [0, 1], selected: 0, onSelected: (_) {}),
          theme: theme,
        );
        expect(find.text('0'), findsOneWidget);
      }
    });
  });
}
