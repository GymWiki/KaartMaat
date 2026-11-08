// QA pass: accessibility guidelines per game panel (tap target size, labels,
// text contrast) in light and dark. Results are printed for the report; a
// guideline miss is a finding, not a failure of this suite.
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/db/database.dart';
import 'package:kaartmaat/core/theme/app_theme.dart';
import 'package:kaartmaat/features/games/data/draft_store.dart';
import 'package:kaartmaat/features/games/data/game_state.dart';
import 'package:kaartmaat/features/games/games_registry.dart';
import 'package:kaartmaat/features/games/ui/game_screen_scaffold.dart';
import 'package:kaartmaat/features/games/ui/panel_context.dart';
import 'package:kaartmaat/features/settings/data/settings_repository.dart';

import '../helpers.dart';

const _names = ['Anna', 'Bas', 'Chris', 'Dora', 'Eva', 'Femke'];

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  final report = <String>[];
  tearDownAll(() {
    // ignore: avoid_print
    print('QA A11Y\n${report.join('\n')}');
  });

  const games = [
    ('boerenbridge', 4),
    ('klaverjassen', 4),
    ('rikken', 4),
    ('hartenjagen', 4),
    ('toepen', 4),
    ('jokeren', 4),
    ('canasta', 4),
    ('duizenden', 4),
    ('custom', 4),
  ];

  for (final (type, players) in games) {
    for (final dark in [false, true]) {
      testWidgets('$type ${dark ? 'dark' : 'light'}', (tester) async {
        final handle = tester.ensureSemantics();
        usePhoneScreen(tester);
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
          Scaffold(
            appBar: AppBar(title: const Text('Spel')),
            body: GameScreenScaffold(
              top: const SizedBox.expand(),
              panel: panel,
            ),
          ),
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          scaffold: false,
          overrides: [prefsProvider.overrideWithValue(const AppPrefs({}))],
        );
        await tester.pump();
        final tag = '$type ${dark ? 'dark' : 'light'}';
        for (final (name, guideline) in [
          ('tap target size 48dp', androidTapTargetGuideline),
          ('labeled tap targets', labeledTapTargetGuideline),
          ('text contrast', textContrastGuideline),
        ]) {
          try {
            await expectLater(tester, meetsGuideline(guideline));
            report.add('$tag | $name | pass');
          } on TestFailure catch (e) {
            report.add(
              '$tag | $name | FAIL ${e.message?.split('\n').take(3).join(' / ')}',
            );
          }
        }
        handle.dispose();
      });
    }
  }
}
