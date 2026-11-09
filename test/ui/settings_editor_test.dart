import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/games/rules/boerenbridge_rules.dart';
import 'package:kaartmaat/features/games/rules/duizenden_rules.dart';
import 'package:kaartmaat/features/settings/ui/settings_editor.dart';

import '../helpers.dart';

void main() {
  testWidgets('Boerenbridge: "Bieden mag niet kloppen" with its explanation', (
    tester,
  ) async {
    const rules = BoerenbridgeRules();
    await pumpApp(
      tester,
      SingleChildScrollView(
        child: SettingsEditor(
          rules: rules,
          values: rules.defaultSettings,
          onChanged: (_, _) {},
        ),
      ),
    );
    expect(find.text('Bieden mag niet kloppen'), findsOneWidget);
    expect(find.text('Beperking voor de deler'), findsNothing);
    expect(
      find.text(
        'Het totaal van alle biedingen mag niet gelijk zijn aan het aantal slagen. Zo is er altijd een verliezer.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Duizenden: only the target score is a setting', (tester) async {
    const rules = DuizendenRules();
    await pumpApp(
      tester,
      SettingsEditor(
        rules: rules,
        values: rules.defaultSettings,
        onChanged: (_, _) {},
      ),
    );
    expect(find.text('Doelscore (0 = geen)'), findsOneWidget);
    expect(find.text('Laagste score per ronde'), findsNothing);
    expect(find.text('Hoogste score per ronde'), findsNothing);
  });
}
