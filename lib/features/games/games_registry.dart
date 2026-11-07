import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import 'data/game_state.dart';
import 'rules/boerenbridge_rules.dart';
import 'rules/canasta_rules.dart';
import 'rules/custom_rules.dart';
import 'rules/game_rules.dart';
import 'rules/hearts_rules.dart';
import 'rules/jokeren_rules.dart';
import 'rules/klaverjas_rules.dart';
import 'rules/rikken_rules.dart';
import 'rules/toepen_rules.dart';
import 'ui/boerenbridge_entry.dart';
import 'ui/calculator_entry.dart';
import 'ui/canasta_header.dart';
import 'ui/boerenbridge_header.dart';
import 'ui/boerenbridge_panel.dart';
import 'ui/panel_context.dart';
import 'ui/hearts_entry.dart';
import 'ui/klaverjas_entry.dart';
import 'ui/klaverjas_header.dart';
import 'ui/klaverjas_panel.dart';
import 'ui/points_entry.dart';
import 'ui/rikken_entry.dart';
import 'ui/toepen_entry.dart';
import 'ui/toepen_header.dart';

/// Builds the score-entry body for one round. Call [onSubmit] with the
/// entries; the screen validates them with the game's rules.
typedef RoundEntryBuilder = Widget Function(
  GameView view,
  int number,
  Entries? existing,
  void Function(Entries entries) onSubmit,
);

class GameDefinition {
  const GameDefinition({
    required this.rules,
    required this.icon,
    required this.name,
    required this.description,
    required this.entryBuilder,
    this.headerBuilder,
    this.primaryLabel,
    this.newGameHint,
    this.panelBuilder,
    this.cellDetail,
    this.cellHighlight,
  });

  final GameRules rules;
  final IconData icon;
  final String Function(AppLocalizations l10n) name;
  final String Function(AppLocalizations l10n) description;
  final RoundEntryBuilder entryBuilder;

  /// Optional block above the scoreboard (round, dealer, ...).
  final Widget Function(GameView view)? headerBuilder;

  /// Label of the big bottom button. Defaults to "Ronde N invoeren".
  final String Function(AppLocalizations l10n, GameView view)? primaryLabel;

  /// Extra explanation on the new-game screen (e.g. how teams are formed).
  final String Function(AppLocalizations l10n)? newGameHint;

  /// The input panel on the game screen. Games without one still use the
  /// separate input screen.
  final Widget Function(PanelContext ctx)? panelBuilder;

  /// Small second line in a round-table cell (e.g. bid and tricks won).
  final String? Function(AppLocalizations l10n, GameView view, int roundIndex,
      String participant)? cellDetail;

  /// Marks a round-table cell with a check (e.g. an exact bid).
  final bool Function(GameView view, int roundIndex, String participant)?
      cellHighlight;

  String get id => rules.type;
  int get minPlayers => rules.minPlayers;
  int get maxPlayers => rules.maxPlayers;
}

final Map<String, GameDefinition> gameDefinitions = {
  BoerenbridgeRules.typeId: GameDefinition(
    rules: const BoerenbridgeRules(),
    icon: Icons.style,
    name: (l) => l.gameBoerenbridge,
    description: (l) => l.gameBoerenbridgeDesc,
    entryBuilder: (view, number, existing, onSubmit) => BoerenbridgeEntry(
      view: view,
      number: number,
      existing: existing,
      onSubmit: onSubmit,
    ),
    headerBuilder: (view) => BoerenbridgeHeader(view: view),
    panelBuilder: (ctx) => BoerenbridgePanel(ctx: ctx),
    cellDetail: (l, view, i, p) {
      final e = view.state.rounds[i].entries[p];
      final bid = e?['bid'];
      if (bid is! int) return null;
      final tricks = e?['tricks'];
      return tricks is int ? l.bidAndWon(bid, tricks) : l.bidShort(bid);
    },
    cellHighlight: (view, i, p) {
      final e = view.state.rounds[i].entries[p];
      return e?['bid'] is int && e?['bid'] == e?['tricks'];
    },
    primaryLabel: (l, view) => view.openRound != null
        ? l.enterTricks(view.nextRoundNumber)
        : l.enterBids(view.nextRoundNumber),
  ),
  KlaverjasRules.typeId: GameDefinition(
    rules: const KlaverjasRules(),
    icon: Icons.groups,
    name: (l) => l.gameKlaverjassen,
    description: (l) => l.gameKlaverjassenDesc,
    entryBuilder: (view, number, existing, onSubmit) =>
        KlaverjasEntry(view: view, existing: existing, onSubmit: onSubmit),
    headerBuilder: (view) => KlaverjasHeader(view: view),
    newGameHint: (l) => l.teamsHint,
    panelBuilder: (ctx) => KlaverjasPanel(ctx: ctx),
    cellDetail: (l, view, i, team) {
      const rules = KlaverjasRules();
      final round = view.state.rounds[i];
      final entry = round.entries[team];
      if (entry == null) return null;
      final outcome = rules.outcome(view.config, round);
      if (outcome.playing == team && outcome.nat) return l.natInTable;
      if (outcome.playing == team && outcome.pit) return l.pitInTable;
      final roem = rules.roemOf(view.config, entry);
      return roem > 0 ? l.roemInTable(roem) : null;
    },
  ),
  RikkenRules.typeId: GameDefinition(
    rules: const RikkenRules(),
    icon: Icons.looks_4,
    name: (l) => l.gameRikken,
    description: (l) => l.gameRikkenDesc,
    entryBuilder: (view, number, existing, onSubmit) =>
        RikkenEntry(view: view, existing: existing, onSubmit: onSubmit),
  ),
  HeartsRules.typeId: GameDefinition(
    rules: const HeartsRules(),
    icon: Icons.favorite,
    name: (l) => l.gameHartenjagen,
    description: (l) => l.gameHartenjagenDesc,
    entryBuilder: (view, number, existing, onSubmit) =>
        HeartsEntry(view: view, existing: existing, onSubmit: onSubmit),
  ),
  ToepenRules.typeId: GameDefinition(
    rules: const ToepenRules(),
    icon: Icons.filter_5,
    name: (l) => l.gameToepen,
    description: (l) => l.gameToepenDesc,
    entryBuilder: (view, number, existing, onSubmit) => ToepenEntry(
      view: view,
      number: number,
      existing: existing,
      onSubmit: onSubmit,
    ),
    headerBuilder: (view) => ToepenHeader(view: view),
  ),
  JokerenRules.typeId: GameDefinition(
    rules: const JokerenRules(),
    icon: Icons.theater_comedy,
    name: (l) => l.gameJokeren,
    description: (l) => l.gameJokerenDesc,
    entryBuilder: (view, number, existing, onSubmit) => CalculatorEntry(
      view: view,
      existing: existing,
      onSubmit: onSubmit,
      quick: [
        QuickAmount((l) => l.quickJoker, view.config.intSetting(JokerenRules.quickJokerKey)),
        QuickAmount((l) => l.quickAce, view.config.intSetting(JokerenRules.quickAceKey)),
        QuickAmount((l) => l.quickFace, view.config.intSetting(JokerenRules.quickFaceKey)),
      ],
    ),
  ),
  CanastaRules.typeId: GameDefinition(
    rules: const CanastaRules(),
    icon: Icons.diamond,
    name: (l) => l.gameCanasta,
    description: (l) => l.gameCanastaDesc,
    entryBuilder: (view, number, existing, onSubmit) => CalculatorEntry(
      view: view,
      existing: existing,
      onSubmit: onSubmit,
      quick: [
        QuickAmount((l) => l.quickNaturalCanasta, view.config.intSetting(CanastaRules.naturalCanastaKey)),
        QuickAmount((l) => l.quickMixedCanasta, view.config.intSetting(CanastaRules.mixedCanastaKey)),
        QuickAmount((l) => l.quickGoOut, view.config.intSetting(CanastaRules.goOutKey)),
        QuickAmount((l) => l.quickGoOutConcealed, view.config.intSetting(CanastaRules.goOutConcealedKey)),
        QuickAmount((l) => l.quickRedThree, view.config.intSetting(CanastaRules.redThreeKey)),
        QuickAmount((l) => l.quickAllRedThrees, view.config.intSetting(CanastaRules.allRedThreesKey)),
      ],
    ),
    headerBuilder: (view) => CanastaHeader(view: view),
    newGameHint: (l) => l.teamsHint,
  ),
  CustomRules.typeId: GameDefinition(
    rules: const CustomRules(),
    icon: Icons.edit_note,
    name: (l) => l.gameCustom,
    description: (l) => l.gameCustomDesc,
    entryBuilder: (view, number, existing, onSubmit) =>
        PointsEntry(view: view, existing: existing, onSubmit: onSubmit),
  ),
};

GameDefinition definitionFor(String type) =>
    gameDefinitions[type] ?? (throw ArgumentError('Unknown game type: $type'));
