import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/games/ui/round_counter_indicator.dart';

import '../helpers.dart';

void main() {
  late ValueNotifier<RoundSignal> signal;
  var undone = 0;

  setUp(() {
    signal = ValueNotifier((tick: 0, message: ''));
    undone = 0;
  });
  tearDown(() => signal.dispose());

  Future<void> pump(WidgetTester tester, {bool canUndo = true}) => pumpApp(
    tester,
    RoundCounterIndicator(
      label: 'Ronde 4',
      roundAdded: signal,
      onUndo: canUndo ? () => undone++ : null,
    ),
  );

  void fire(String message) =>
      signal.value = (tick: signal.value.tick + 1, message: message);

  Color labelColor(WidgetTester tester) =>
      tester.widget<Text>(find.text('Ronde 4')).style!.color!;

  testWidgets('no animation on first load', (tester) async {
    await pump(tester);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('+1'), findsNothing);
  });

  testWidgets('a new round turns the label green and floats a +1', (
    tester,
  ) async {
    await pump(tester);
    final normal = labelColor(tester);
    fire('Ronde 3 opgeslagen');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('+1'), findsOneWidget);
    expect(labelColor(tester), isNot(normal));
    // it drifts up and is gone afterwards; the colour is back to normal
    final y0 = tester.getTopLeft(find.text('+1')).dy;
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.getTopLeft(find.text('+1')).dy, lessThan(y0));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text('+1'), findsNothing);
    expect(labelColor(tester), normal);
  });

  testWidgets('quick successive rounds do not stack particles', (tester) async {
    await pump(tester);
    fire('Ronde 3 opgeslagen');
    await tester.pump(const Duration(milliseconds: 200));
    fire('Ronde 4 opgeslagen');
    await tester.pump(const Duration(milliseconds: 200));
    fire('Ronde 5 opgeslagen');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('+1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('+1'), findsNothing);
    expect(
      labelColor(tester),
      Theme.of(tester.element(find.text('Ronde 4'))).colorScheme.onSurface,
    );
  });

  testWidgets('reduce motion: colour change only, no particle', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pump(tester);
    final normal = labelColor(tester);
    fire('Ronde 3 opgeslagen');
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('+1'), findsNothing);
    expect(labelColor(tester), isNot(normal));
    await tester.pump(const Duration(seconds: 1));
    expect(labelColor(tester), normal);
  });

  testWidgets('announces the saved round to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester);
    fire('Ronde 3 opgeslagen');
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.bySemanticsLabel(RegExp('Ronde 3 opgeslagen')), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.bySemanticsLabel(RegExp('Ronde 3 opgeslagen')), findsNothing);
    handle.dispose();
  });

  testWidgets('undo button: 48dp, works, disabled without undo', (
    tester,
  ) async {
    await pump(tester);
    final size = tester.getSize(find.byTooltip('Ongedaan maken'));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    await tester.tap(find.byTooltip('Ongedaan maken'));
    expect(undone, 1);

    await pump(tester, canUndo: false);
    expect(
      tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.undo))
          .onPressed,
      isNull,
    );
  });
}
