import 'package:flutter/foundation.dart';

import '../data/draft_store.dart';
import '../data/game_state.dart';
import '../rules/game_rules.dart';

/// Everything an input panel needs from the game screen it lives in.
class PanelContext {
  const PanelContext({
    required this.view,
    required this.roundNumber,
    required this.existing,
    required this.editing,
    required this.draft,
    required this.initialDraft,
    required this.onSave,
    required this.onCancel,
  });

  final GameView view;

  /// The round being entered, or corrected when [editing] is true.
  final int roundNumber;

  /// What is stored for [roundNumber]: null for a new round, bids only for an
  /// open round, everything for a finished one.
  final Entries? existing;

  /// True when an earlier, finished round is being corrected.
  final bool editing;

  /// Debounced storage for the half-filled panel.
  final DraftSaver draft;

  /// The draft found when the screen opened (may belong to another round, so
  /// check its `round` and `editing` before using it).
  final Map<String, Object?>? initialDraft;

  /// Stores the round. [complete] false saves a partial round (for example the
  /// bids) without finishing it. [undoDraft] is what the panel should show
  /// again if the user undoes the save.
  final Future<void> Function(
    Entries entries, {
    required bool complete,
    Map<String, Object?>? undoDraft,
  }) onSave;

  /// Leaves editing mode without saving.
  final VoidCallback onCancel;
}
