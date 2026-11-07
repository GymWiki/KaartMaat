import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import 'data/game_state.dart';
import 'rules/boerenbridge_rules.dart';
import 'rules/custom_rules.dart';
import 'rules/game_rules.dart';
import 'ui/boerenbridge_entry.dart';
import 'ui/boerenbridge_header.dart';
import 'ui/points_entry.dart';

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
    primaryLabel: (l, view) => view.openRound != null
        ? l.enterTricks(view.nextRoundNumber)
        : l.enterBids(view.nextRoundNumber),
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

/// Planned games, shown as disabled tiles until their phase is built.
final List<(IconData, String Function(AppLocalizations))> comingSoonGames = [
  (Icons.groups, (l) => l.gameKlaverjassen),
  (Icons.casino, (l) => l.gameYatzy),
  (Icons.filter_5, (l) => l.gameToepen),
  (Icons.looks_4, (l) => l.gameRikken),
  (Icons.favorite, (l) => l.gameHartenjagen),
];
