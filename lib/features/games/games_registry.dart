import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import 'data/game_state.dart';
import 'rules/boerenbridge_rules.dart';
import 'rules/canasta_rules.dart';
import 'rules/custom_rules.dart';
import 'rules/duizenden_rules.dart';
import 'rules/game_rules.dart';
import 'rules/hearts_rules.dart';
import 'rules/jokeren_rules.dart';
import 'rules/klaverjas_rules.dart';
import 'rules/rikken_rules.dart';
import 'rules/toepen_rules.dart';
import 'ui/boerenbridge_entry.dart';
import 'ui/calculator_entry.dart';
import 'ui/counter_panel.dart';
import 'ui/calculator_panel.dart';
import 'ui/canasta_header.dart';
import 'ui/boerenbridge_header.dart';
import 'ui/boerenbridge_panel.dart';
import 'ui/panel_context.dart';
import 'ui/hearts_entry.dart';
import 'ui/hearts_panel.dart';
import 'ui/klaverjas_entry.dart';
import 'ui/klaverjas_header.dart';
import 'ui/klaverjas_panel.dart';
import 'ui/points_entry.dart';
import 'ui/rikken_entry.dart';
import 'ui/rikken_labels.dart';
import '../../core/ui/suits.dart';
import 'ui/duizenden_panel.dart';
import 'ui/gronings_steps.dart' show suitSign;
import 'ui/rikken_panel.dart';
import 'ui/toepen_panel.dart';

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
    required this.suit,
    required this.name,
    required this.description,
    required this.entryBuilder,
    this.headerBuilder,
    this.primaryLabel,
    this.newGameHint,
    this.panelBuilder,
    this.cellDetail,
    this.cellHighlight,
    this.liveRound = false,
    this.statusLine,
    this.totalDetail,
  });

  final GameRules rules;
  final IconData icon;

  /// The card suit shown on this game's card on the home screen. Fixed per
  /// game, not derived from the order of the list.
  final Suit suit;
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

  /// One line above the table: round, dealer, cards. Defaults to the round
  /// number. [editing] is true while an earlier round is corrected.
  final String Function(
          AppLocalizations l10n, GameView view, int roundNumber, bool editing)?
      statusLine;

  /// Small line under a participant's total in the table (progress to a
  /// target, for example).
  final String? Function(AppLocalizations l10n, GameView view, String participant)?
      totalDetail;

  /// Counting games: the panel edits the latest round on every tap, and
  /// "next round" starts a new one, instead of confirming a round at a time.
  final bool liveRound;

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
    suit: Suit.spades,
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
    statusLine: (l, view, n, editing) {
      const rules = BoerenbridgeRules();
      final cfg = view.config;
      return [
        editing ? l.editRound(n) : l.roundOf(n, rules.totalRounds(cfg)),
        l.cardsCount(rules.cardsInRound(cfg, n)),
        l.dealerLabel(view.nameOf(rules.dealer(cfg, n))),
      ].join(' · ');
    },
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
    suit: Suit.clubs,
    name: (l) => l.gameKlaverjassen,
    description: (l) => l.gameKlaverjassenDesc,
    entryBuilder: (view, number, existing, onSubmit) =>
        KlaverjasEntry(view: view, existing: existing, onSubmit: onSubmit),
    headerBuilder: (view) => KlaverjasHeader(view: view),
    newGameHint: (l) => l.teamsHint,
    panelBuilder: (ctx) => KlaverjasPanel(ctx: ctx),
    statusLine: (l, view, n, editing) {
      const rules = KlaverjasRules();
      final cfg = view.config;
      final total = rules.plannedRounds(cfg);
      return [
        editing
            ? l.editRound(n)
            : (total == null ? l.roundTitle(n) : l.roundOf(n, total)),
        l.dealerLabel(view.nameOf(rules.dealer(cfg, n))),
      ].join(' · ');
    },
    cellDetail: (l, view, i, team) {
      const rules = KlaverjasRules();
      final round = view.state.rounds[i];
      final entry = round.entries[team];
      if (entry == null) return null;
      final outcome = rules.outcome(view.config, round);
      // Gronings: bid, trump and bidder in one short line for the playing team
      if (outcome.playing == team && outcome.bid != null) {
        final sign = suitSign('${entry['suit']}');
        final tail = outcome.nat
            ? l.natInTable
            : outcome.pit
            ? l.pitInTable
            : view.nameOf('${entry['bidder']}');
        return '${outcome.bid}$sign $tail';
      }
      if (outcome.playing == team && outcome.nat) return l.natInTable;
      if (outcome.playing == team && outcome.pit) return l.pitInTable;
      final roem = rules.roemOf(view.config, entry);
      return roem > 0 ? l.roemInTable(roem) : null;
    },
  ),
  RikkenRules.typeId: GameDefinition(
    rules: const RikkenRules(),
    icon: Icons.looks_4,
    suit: Suit.diamonds,
    name: (l) => l.gameRikken,
    description: (l) => l.gameRikkenDesc,
    entryBuilder: (view, number, existing, onSubmit) =>
        RikkenEntry(view: view, existing: existing, onSubmit: onSubmit),
    panelBuilder: (ctx) => RikkenPanel(ctx: ctx),
    cellDetail: (l, view, i, p) {
      final entry = view.state.rounds[i].entries[p];
      return switch (entry?['role']) {
        'bidder' => rikContractShort(l, '${entry?['contract']}'),
        'partner' => l.rikPartnerShort,
        _ => null,
      };
    },
  ),
  HeartsRules.typeId: GameDefinition(
    rules: const HeartsRules(),
    icon: Icons.favorite,
    suit: Suit.hearts,
    name: (l) => l.gameHartenjagen,
    description: (l) => l.gameHartenjagenDesc,
    entryBuilder: (view, number, existing, onSubmit) =>
        HeartsEntry(view: view, existing: existing, onSubmit: onSubmit),
    panelBuilder: (ctx) => HeartsPanel(ctx: ctx),
    cellDetail: (l, view, i, p) {
      final entry = view.state.rounds[i].entries[p];
      if (entry?['moon'] == true) return l.heartsMoon;
      if (entry?['queen'] == true) return l.heartsQueenShort;
      return null;
    },
  ),
  ToepenRules.typeId: GameDefinition(
    rules: const ToepenRules(),
    icon: Icons.filter_5,
    suit: Suit.spades,
    name: (l) => l.gameToepen,
    description: (l) => l.gameToepenDesc,
    entryBuilder: (view, number, existing, onSubmit) =>
        PointsEntry(view: view, existing: existing, onSubmit: onSubmit),
    panelBuilder: (ctx) => ToepenPanel(ctx: ctx),
    liveRound: true,
  ),
  JokerenRules.typeId: GameDefinition(
    rules: const JokerenRules(),
    icon: Icons.theater_comedy,
    suit: Suit.hearts,
    name: (l) => l.gameJokeren,
    description: (l) => l.gameJokerenDesc,
    entryBuilder: (view, number, existing, onSubmit) => CalculatorEntry(
      view: view,
      existing: existing,
      onSubmit: onSubmit,
      quick: _jokerenQuick(view.config),
    ),
    panelBuilder: (ctx) =>
        CalculatorPanel(ctx: ctx, quick: _jokerenQuick(ctx.view.config)),
  ),
  CanastaRules.typeId: GameDefinition(
    rules: const CanastaRules(),
    icon: Icons.diamond,
    suit: Suit.clubs,
    name: (l) => l.gameCanasta,
    description: (l) => l.gameCanastaDesc,
    entryBuilder: (view, number, existing, onSubmit) => CalculatorEntry(
      view: view,
      existing: existing,
      onSubmit: onSubmit,
      quick: _canastaQuick(view.config),
    ),
    headerBuilder: (view) => CanastaHeader(view: view),
    newGameHint: (l) => l.teamsHint,
    panelBuilder: (ctx) =>
        CalculatorPanel(ctx: ctx, quick: _canastaQuick(ctx.view.config)),
  ),
  DuizendenRules.typeId: GameDefinition(
    rules: const DuizendenRules(),
    icon: Icons.trending_up,
    suit: Suit.diamonds,
    name: (l) => l.gameDuizenden,
    description: (l) => l.gameDuizendenDesc,
    entryBuilder: (view, number, existing, onSubmit) =>
        PointsEntry(view: view, existing: existing, onSubmit: onSubmit),
    newGameHint: (l) => l.duizendenHint,
    panelBuilder: (ctx) => DuizendenPanel(ctx: ctx),
    totalDetail: (l, view, p) {
      final total = view.standings.firstWhere((s) => s.participant == p).total;
      final target = view.config.intSetting(DuizendenRules.targetScoreKey);
      if (target <= 0 || view.state.rounds.isEmpty) return null;
      final left = const DuizendenRules().toGo(view.config, total);
      return left == 0 ? l.duizendenReached : l.duizendenToGo(left);
    },
  ),
  CustomRules.typeId: GameDefinition(
    rules: const CustomRules(),
    icon: Icons.edit_note,
    suit: Suit.spades,
    name: (l) => l.gameCustom,
    description: (l) => l.gameCustomDesc,
    entryBuilder: (view, number, existing, onSubmit) =>
        PointsEntry(view: view, existing: existing, onSubmit: onSubmit),
    panelBuilder: (ctx) => CounterPanel(ctx: ctx),
    liveRound: true,
  ),
};

/// Quick amounts (values from the game settings) for the calculator input.
List<QuickAmount> _jokerenQuick(GameConfig c) => [
      QuickAmount((l) => l.quickJoker, c.intSetting(JokerenRules.quickJokerKey)),
      QuickAmount((l) => l.quickAce, c.intSetting(JokerenRules.quickAceKey)),
      QuickAmount((l) => l.quickFace, c.intSetting(JokerenRules.quickFaceKey)),
    ];

List<QuickAmount> _canastaQuick(GameConfig c) => [
      QuickAmount((l) => l.quickNaturalCanasta, c.intSetting(CanastaRules.naturalCanastaKey)),
      QuickAmount((l) => l.quickMixedCanasta, c.intSetting(CanastaRules.mixedCanastaKey)),
      QuickAmount((l) => l.quickGoOut, c.intSetting(CanastaRules.goOutKey)),
      QuickAmount((l) => l.quickGoOutConcealed, c.intSetting(CanastaRules.goOutConcealedKey)),
      QuickAmount((l) => l.quickRedThree, c.intSetting(CanastaRules.redThreeKey)),
      QuickAmount((l) => l.quickAllRedThrees, c.intSetting(CanastaRules.allRedThreesKey)),
    ];

GameDefinition definitionFor(String type) =>
    gameDefinitions[type] ?? (throw ArgumentError('Unknown game type: $type'));
