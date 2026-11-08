// QA pass: every game's input panel on small / normal / large screens, with
// system font size 100% and 200%, portrait and landscape. Reports overflow
// exceptions (hard failures) and how much of the panel needs scrolling.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/features/games/data/draft_store.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/games_registry.dart';
import 'package:kaartmaat/features/games/ui/game_screen_scaffold.dart';
import 'package:kaartmaat/features/games/ui/panel_context.dart';
import 'package:kaartmaat/features/settings/data/settings_repository.dart';

import '../helpers.dart';

const _names = [
  'Anna',
  'Bas',
  'Chris',
  'Dora',
  'Eva',
  'Femke',
  'Gijs',
  'Hanna',
];

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  // (game type, players). Player counts: the most crowded legal table.
  const games = [
    ('boerenbridge', 7),
    ('klaverjassen', 4),
    ('rikken', 4),
    ('hartenjagen', 6),
    ('toepen', 8),
    ('jokeren', 8),
    ('canasta', 4),
    ('custom', 8),
  ];
  // name, logical size (w x h), text scale
  const screens = [
    ('small 360x640 @100%', Size(360, 640), 1.0),
    ('small 360x640 @200%', Size(360, 640), 2.0),
    ('normal 411x914 @100%', Size(411, 914), 1.0),
    ('normal 411x914 @200%', Size(411, 914), 2.0),
    ('large 600x1024 @200%', Size(600, 1024), 2.0),
    ('landscape 914x411 @100%', Size(914, 411), 1.0),
    ('landscape 914x411 @200%', Size(914, 411), 2.0),
  ];

  final report = <String>[];
  tearDownAll(() {
    // ignore: avoid_print
    print('QA LAYOUT MATRIX\n${report.join('\n')}');
  });

  for (final (type, players) in games) {
    for (final (label, size, scale) in screens) {
      testWidgets('$type, $players players, $label', (tester) async {
        final errors = <String>[];
        final oldHandler = FlutterError.onError;
        FlutterError.onError = (d) => errors.add(
          d.exceptionAsString().split(String.fromCharCode(10)).first,
        );
        addTearDown(() => FlutterError.onError = oldHandler);
        tester.view.physicalSize = size * 2.625;
        tester.view.devicePixelRatio = 2.625;
        addTearDown(tester.view.reset);
        final def = definitionFor(type);
        final s = GameState(
          id: 1,
          type: type,
          createdAt: DateTime(2026, 5, 1),
          finishedAt: null,
          settings: def.rules.defaultSettings,
          players: [
            for (var i = 0; i < players; i++)
              PlayerRef(id: i + 1, name: _names[i]),
          ],
          rounds: const [],
        );
        final panel = def.panelBuilder!(
          PanelContext(
            view: GameView(s),
            roundNumber: 1,
            existing: null,
            editing: false,
            draft: DraftSaver(DraftStore(SettingsRepository(db)), 1),
            initialDraft: null,
            onSave: (entries, {required complete, undoDraft}) async {},
            onCancel: () {},
            onNewRound: (entries) async {},
          ),
        );
        await pumpApp(
          tester,
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                appBar: AppBar(title: const Text('Spel')),
                body: GameScreenScaffold(
                  top: const SizedBox.expand(),
                  panel: panel,
                ),
              ),
            ),
          ),
          scaffold: false,
          overrides: [prefsProvider.overrideWithValue(const AppPrefs({}))],
        );
        await tester.pump();
        tester.takeException();
        final exception = errors.isEmpty ? null : errors.toSet().join(' | ');
        double hidden = -1;
        final scrollables = find.descendant(
          of: find.byType(GameScreenScaffold),
          matching: find.byType(Scrollable),
        );
        if (scrollables.evaluate().isNotEmpty) {
          hidden = tester
              .state<ScrollableState>(scrollables.first)
              .position
              .maxScrollExtent;
        }
        final line =
            '$type/${players}p $label: ${exception != null ? 'EXCEPTION ${exception.toString().split('\n').first}' : 'ok'}, panel scrolls ${hidden.toStringAsFixed(0)} dp';
        report.add(line);
        // Only the baseline (normal phone, 100% font) is a hard requirement here;
        // the other cells are findings, listed in docs/qa-report.md.
        if (label.startsWith('normal 411x914 @100%')) {
          expect(exception, isNull, reason: line);
        }
      });
    }
  }
}
