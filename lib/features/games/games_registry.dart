import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import 'data/game_state.dart';
import 'rules/custom_rules.dart';
import 'rules/game_rules.dart';
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
    required this.isFree,
    required this.icon,
    required this.name,
    required this.description,
    required this.entryBuilder,
  });

  final GameRules rules;
  final bool isFree;
  final IconData icon;
  final String Function(AppLocalizations l10n) name;
  final String Function(AppLocalizations l10n) description;
  final RoundEntryBuilder entryBuilder;
}

final Map<String, GameDefinition> gameDefinitions = {
  CustomRules.typeId: GameDefinition(
    rules: const CustomRules(),
    isFree: true,
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
  (Icons.style, (l) => l.gameBoerenbridge),
  (Icons.groups, (l) => l.gameKlaverjassen),
  (Icons.casino, (l) => l.gameYatzy),
  (Icons.filter_5, (l) => l.gameToepen),
  (Icons.looks_4, (l) => l.gameRikken),
  (Icons.favorite, (l) => l.gameHartenjagen),
];
