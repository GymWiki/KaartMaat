import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/features/games/rules/game_rules.dart';
import 'package:kaartmaat/features/games/rules/rules_registry.dart';
import 'package:kaartmaat/features/rulebook/rulebook.dart';
import 'package:kaartmaat/features/rulebook/rulebook_sheet.dart';

import '../helpers.dart';

Rulebook book(String type, [Map<String, Object?> settings = const {}]) {
  final json =
      jsonDecode(File(Rulebook.path(type)).readAsStringSync())
          as Map<String, dynamic>;
  return Rulebook.parse(json, Rulebook.valuesFor(type, settings));
}

void main() {
  test(
    'every game has a rulebook with all sections and no loose placeholders',
    () {
      for (final type in allRules.keys) {
        final b = book(type);
        expect(b.title, isNotEmpty, reason: type);
        expect(b.goal, isNotEmpty, reason: type);
        expect(b.needs, isNotEmpty, reason: type);
        expect(b.flow, isNotEmpty, reason: type);
        expect(
          b.scoringTable.isNotEmpty || b.scoringNotes.isNotEmpty,
          isTrue,
          reason: type,
        );
        for (final t in b.allTexts) {
          expect(
            t.contains(RegExp(r'\{[\w.]+\}')),
            isFalse,
            reason: '$type: placeholder left in "$t"',
          );
        }
      }
    },
  );

  test('every variant of every choice setting leaves no placeholder', () {
    for (final entry in allRules.entries) {
      for (final spec in entry.value.settingSpecs) {
        final values = spec.options.isNotEmpty
            ? spec.options
            : spec.kind == SettingKind.boolean
            ? <Object>[true, false]
            : <Object>[0, 5];
        for (final v in values) {
          final b = book(entry.key, {spec.key: v});
          for (final t in b.allTexts) {
            expect(
              t.contains(RegExp(r'\{[\w.]+\}')),
              isFalse,
              reason: '${entry.key} ${spec.key}=$v: "$t"',
            );
          }
        }
      }
    }
  });

  test('scoring shows the settings of the game', () {
    final k = book('klaverjassen', {'roemThree': 30, 'pitBonus': 250});
    final rows = {for (final r in k.scoringTable) r.first: r.last};
    expect(rows['Roem: drie opeenvolgende kaarten van één kleur'], '30');
    expect(rows['Bonus voor pit (alle 8 slagen)'], '250');

    final r = book('rikken', {'base.rik': 12});
    expect(
      r.scoringTable.firstWhere((x) => x.first == 'Rik (met maat)').last,
      '12',
    );

    final bb = book('boerenbridge', {'exactBase': 7, 'wrongPerTrick': 3});
    expect(bb.scoringTable.first.last, contains('7 +'));
    expect(bb.scoringTable[1].last, contains('3'));
  });

  test('variants and switches change the text', () {
    final gron = book('klaverjassen', {'variant': 'gronings', 'minBid': 80});
    expect(gron.flow.any((s) => s.contains('Een eerste bod')), isTrue);
    expect(gron.flow.any((s) => s.contains('80')), isTrue);
    expect(
      book('klaverjassen').flow.any((s) => s.contains('Een eerste bod')),
      isFalse,
    );

    expect(book('hartenjagen').rules.first.title, 'De maan schieten');
    expect(
      book('hartenjagen', {'moonEnabled': false}).rules.first.title,
      'De maan schieten staat uit',
    );
    expect(book('hartenjagen', {'targetScore': 50}).goal.first, contains('50'));
    expect(
      book('custom', {'inputMode': 'enter'}).flow.join(' '),
      contains('cijferblok'),
    );
  });

  Future<void> open(WidgetTester tester, String type) async {
    usePhoneScreen(tester);
    await pumpApp(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () =>
              showRulebook(context, type: type, settings: const {}),
          child: const Text('open'),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the sheet shows the sections and jumps to one', (tester) async {
    await open(tester, 'boerenbridge');
    expect(find.text('Spelregels: Boerenbridge'), findsOneWidget);
    for (final s in ['Doel', 'Benodigdheden', 'Spelverloop', 'Puntentelling']) {
      expect(find.text(s), findsWidgets);
    }
    // the chip row scrolls sideways
    await tester.drag(find.byType(ActionChip).first, const Offset(-250, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ActionChip, 'Puntentelling'));
    await tester.pumpAndSettle();
    expect(find.text('Met de instellingen van dit spel'), findsOneWidget);
    expect(find.textContaining('10 + 5 per gewonnen slag'), findsOneWidget);
  });
}
