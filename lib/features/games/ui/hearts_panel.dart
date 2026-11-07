import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/player_selector.dart';
import '../../../core/ui/quick_button_row.dart';
import '../../../core/ui/touch.dart';
import '../../settings/data/settings_repository.dart';
import '../rules/game_rules.dart';
import '../rules/hearts_rules.dart';
import 'panel_context.dart';

/// Hartenjagen input on the game screen.
///
/// Pick a player, tap how many hearts they took (0-13), tap "Schoppen Vrouw"
/// for whoever has the queen, or "Maan" for a player who shot the moon. The
/// last seat is filled in automatically with whatever is left, so 4 players
/// take about 5 taps. The player chips show the penalty points per player, so
/// they double as the live preview.
class HeartsPanel extends ConsumerStatefulWidget {
  const HeartsPanel({super.key, required this.ctx});
  final PanelContext ctx;

  @override
  ConsumerState<HeartsPanel> createState() => _HeartsPanelState();
}

class _HeartsPanelState extends ConsumerState<HeartsPanel> {
  static const _rules = HeartsRules();

  PanelContext get ctx => widget.ctx;
  late final GameConfig config = ctx.view.config;
  late final int number = ctx.roundNumber;
  late final List<String> ids = config.participants;
  late final String last = _rules.lastParticipant(config);
  late final int queenPoints = config.intSetting(HeartsRules.queenPointsKey);
  late final int heartsTotal = _rules.heartsTotal(config);
  late final bool moonEnabled = config.boolSetting(HeartsRules.moonEnabledKey);

  final Map<String, int?> hearts = {};

  /// Who holds the queen of spades. Null means: the last seat (or nobody yet).
  String? queenHolder;
  String? moon;
  int focus = 0;

  @override
  void initState() {
    super.initState();
    for (final p in ids) {
      hearts[p] = null;
    }
    final initial = ctx.initialDraft;
    final usable = initial != null &&
        initial['round'] == number &&
        initial['editing'] == ctx.editing;
    if (usable) {
      final saved = initial['hearts'];
      if (saved is Map) {
        for (final p in ids) {
          final h = saved[p];
          hearts[p] = h is int ? h : null;
        }
      }
      queenHolder = initial['queen'] as String?;
      moon = initial['moon'] as String?;
      focus = initial['focus'] as int? ?? 0;
    } else if (ctx.existing != null) {
      _loadExisting(ctx.existing!);
    }
  }

  void _loadExisting(Entries existing) {
    // Entries store points; split them into hearts and the queen.
    String? queen;
    for (final p in ids) {
      if (existing[p]?['queen'] == true) queen = p;
      if (existing[p]?['moon'] == true) moon = p;
    }
    if (queen == null && moon == null) {
      // older rounds: the player with the most points and at least the queen
      var best = -1;
      for (final p in ids) {
        final pts = existing[p]?['points'];
        if (pts is int && pts >= queenPoints && pts > best) {
          best = pts;
          queen = p;
        }
      }
    }
    queenHolder = queen == last ? null : queen;
    for (final p in ids) {
      final pts = existing[p]?['points'];
      if (pts is! int) continue;
      hearts[p] = pts - (queen == p ? queenPoints : 0);
    }
    focus = ids.length - 1;
  }

  // ---- derived ---------------------------------------------------------

  Map<String, int?> get _heartsForAuto => {...hearts, last: null};

  ({int hearts, bool hasQueen})? get _auto => _rules.autoLast(config, _heartsForAuto, queenHolder);

  Entries? get _entries =>
      _rules.buildEntries(config, hearts: _heartsForAuto, queenHolder: queenHolder, moon: moon);

  RoundIssue? get _issue {
    final e = _entries;
    return e == null ? RoundIssue.missingEntry : _rules.validateRound(config, RoundData(number: number, entries: e));
  }

  /// Points per player as shown on the chips; null while unknown.
  int? _pointsOf(String p) {
    final e = _entries;
    return e == null ? null : e[p]!['points'] as int?;
  }

  bool _holdsQueen(String p) => moon == null && (queenHolder == p || (p == last && queenHolder == null));

  Map<String, Object?> _draftJson() => {
        'round': number,
        'editing': ctx.editing,
        'hearts': hearts,
        'queen': queenHolder,
        'moon': moon,
        'focus': focus,
      };

  void _update(VoidCallback change) {
    haptic(ref);
    setState(change);
    ctx.draft.schedule(_draftJson());
  }

  // ---- actions ---------------------------------------------------------

  void _setHearts(int value) {
    final p = ids[focus];
    if (p == last || moon != null) return;
    _update(() {
      hearts[p] = value;
      // next player that still needs a number (the last seat is automatic)
      final filled = [for (final q in ids) q == last || hearts[q] != null];
      final next = PlayerSelector.nextUnfilled(filled, focus);
      if (next != null) focus = next;
    });
  }

  void _toggleQueen() {
    if (moon != null) return;
    final p = ids[focus];
    _update(() {
      if (p == last) {
        queenHolder = null; // the last seat holds it by default
      } else {
        queenHolder = queenHolder == p ? null : p;
      }
    });
  }

  void _toggleMoon() {
    final p = ids[focus];
    _update(() => moon = moon == p ? null : p);
  }

  void _confirm() {
    final entries = _entries;
    if (entries == null) return;
    haptic(ref);
    ctx.onSave(entries, complete: true, undoDraft: ctx.editing ? null : _draftJson());
  }

  // ---- build -----------------------------------------------------------

  Widget _toggleButton({
    required String label,
    required bool selected,
    required VoidCallback? onTap,
    required double width,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: kTouchTarget,
        child: Material(
          color: selected ? scheme.primary : scheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: selected ? scheme.primary : scheme.outlineVariant),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: onTap == null
                          ? scheme.onSurface.withValues(alpha: 0.38)
                          : selected
                              ? AppTheme.ink
                              : scheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final view = ctx.view;
    final player = ids[focus];
    final isLast = player == last;
    final entries = _entries;
    final issue = _issue;
    final canConfirm = entries != null && issue == null;

    final heartsLeft = _rules.heartsLeftFor(config, player, hearts);
    final disabledHearts = <int>{
      if (isLast || moon != null)
        for (var i = 0; i <= heartsTotal; i++) i
      else
        for (var i = heartsLeft + 1; i <= heartsTotal; i++) i,
    };
    final selectedHearts = isLast
        ? _auto?.hearts
        : hearts[player];

    final handedOut = entries == null
        ? ids.fold<int>(0, (a, p) => a + (_pointsOf(p) ?? 0))
        : ids.fold<int>(0, (a, p) => a + (entries[p]!['points'] as int));

    String? message;
    if (entries == null) {
      final auto = _auto;
      message = auto == null && ids.where((p) => p != last).every((p) => hearts[p] != null)
          ? l10n.heartsTooMany
          : null;
    } else if (issue != null) {
      message = l10n.heartsQueenMissing;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ctx.editing)
          Row(children: [
            Expanded(
              child: Text(
                l10n.editRound(number),
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: l10n.cancel,
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: ctx.onCancel,
              icon: const Icon(Icons.close),
            ),
          ]),
        PlayerSelector(
          chips: [
            for (final p in ids)
              PlayerChipData(
                label: [
                  view.nameOf(p),
                  if (_holdsQueen(p)) l10n.heartsQueenShort,
                  if (moon == p) l10n.heartsMoon,
                ].join(' · '),
                value: _pointsOf(p)?.toString(),
                done: _pointsOf(p) != null,
              ),
          ],
          selectedIndex: focus,
          onSelected: (i) {
            haptic(ref);
            setState(() => focus = i);
            ctx.draft.schedule(_draftJson());
          },
        ),
        const SizedBox(height: kTouchGap),
        QuickButtonRow(
          values: [for (var i = 0; i <= heartsTotal; i++) i],
          selected: moon != null ? null : selectedHearts,
          disabled: disabledHearts,
          onSelected: _setHearts,
        ),
        const SizedBox(height: kTouchGap),
        LayoutBuilder(builder: (context, constraints) {
          const gaps = kTouchGap * 2;
          final queenWidth = (constraints.maxWidth - gaps) * 0.34;
          final moonWidth = (constraints.maxWidth - gaps) * 0.2;
          return Row(children: [
            _toggleButton(
              label: l10n.heartsQueen(queenPoints),
              selected: _holdsQueen(player),
              onTap: moon != null ? null : _toggleQueen,
              width: queenWidth,
            ),
            const SizedBox(width: kTouchGap),
            if (moonEnabled) ...[
              _toggleButton(
                label: l10n.heartsMoon,
                selected: moon == player,
                onTap: _toggleMoon,
                width: moonWidth,
              ),
              const SizedBox(width: kTouchGap),
            ],
            Expanded(
              child: SizedBox(
                height: kTouchTarget,
                child: FilledButton(
                  onPressed: canConfirm ? _confirm : null,
                  child: FittedBox(fit: BoxFit.scaleDown, child: Text(l10n.saveRound)),
                ),
              ),
            ),
          ]);
        }),
        const SizedBox(height: 6),
        Text(
          message ??
              (moon != null
                  ? l10n.heartsMoonShot
                  : l10n.heartsHandedOut(handedOut, config.intSetting(HeartsRules.totalPointsKey))),
          style: text.bodySmall?.copyWith(
            color: message != null ? scheme.error : scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
