import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/big_number_pad.dart' show applyKey;
import '../../../core/ui/live_score_preview.dart';
import '../../../core/ui/touch.dart';
import '../../../core/ui/wide_digit_pad.dart';
import '../../settings/data/settings_repository.dart';
import '../rules/game_rules.dart';
import '../rules/klaverjas_rules.dart';
import 'panel_context.dart';

/// Klaverjassen input on the game screen.
///
/// Team toggle (preselected: the team of the player left of the dealer), the
/// playing team's card points on a compact pad (the other team gets the rest
/// of the 162 by itself), roem as tap-to-add buttons on a second page, and a
/// Pit switch. Nat is worked out from the points and shown in the preview.
class KlaverjasPanel extends ConsumerStatefulWidget {
  const KlaverjasPanel({super.key, required this.ctx});
  final PanelContext ctx;

  @override
  ConsumerState<KlaverjasPanel> createState() => _KlaverjasPanelState();
}

class _KlaverjasPanelState extends ConsumerState<KlaverjasPanel> {
  static const _rules = KlaverjasRules();
  static const _teams = [KlaverjasRules.wij, KlaverjasRules.zij];

  PanelContext get ctx => widget.ctx;
  late final GameConfig config = ctx.view.config;
  late final int number = ctx.roundNumber;

  late String playing;
  String cards = '';
  bool pit = false;
  bool roemPage = false;
  final Map<String, Map<String, int>> roem = {
    for (final t in _teams)
      t: {for (final f in KlaverjasRules.roemFields) f: 0},
  };

  @override
  void initState() {
    super.initState();
    playing = _rules.forehandTeam(config, number);
    final initial = ctx.initialDraft;
    final usable =
        initial != null &&
        initial['round'] == number &&
        initial['editing'] == ctx.editing;
    if (usable) {
      playing = initial['playing'] as String? ?? playing;
      cards = initial['cards'] as String? ?? '';
      pit = initial['pit'] == true;
      roemPage = initial['page'] == 'roem';
      final saved = initial['roem'];
      if (saved is Map) {
        for (final t in _teams) {
          final counts = saved[t];
          if (counts is Map) {
            for (final f in KlaverjasRules.roemFields) {
              final n = counts[f];
              roem[t]![f] = n is int ? n : 0;
            }
          }
        }
      }
    } else if (ctx.existing != null) {
      for (final t in _teams) {
        final e = ctx.existing![t];
        if (e == null) continue;
        if (e['playing'] == true) {
          playing = t;
          pit = e['pit'] == true;
          cards = pit ? '' : '${e['cards'] ?? ''}';
        }
        for (final f in KlaverjasRules.roemFields) {
          final n = e[f];
          roem[t]![f] = n is int ? n : 0;
        }
      }
    }
  }

  // ---- derived ---------------------------------------------------------

  int? get _cardsValue =>
      pit ? KlaverjasRules.totalCardPoints : int.tryParse(cards);

  Entries _entries() {
    final value = _cardsValue;
    return {
      for (final t in _teams)
        t: {
          'playing': t == playing,
          'pit': pit && t == playing,
          if (value != null)
            'cards': t == playing
                ? value
                : KlaverjasRules.totalCardPoints - value,
          ...roem[t]!,
        },
    };
  }

  RoundData get _round => RoundData(number: number, entries: _entries());

  Map<String, Object?> _draftJson() => {
    'round': number,
    'editing': ctx.editing,
    'playing': playing,
    'cards': cards,
    'pit': pit,
    'page': roemPage ? 'roem' : 'points',
    'roem': roem,
  };

  void _saveDraft() => ctx.draft.schedule(_draftJson());

  int _roemTotal(String team) => _rules.roemOf(config, {...roem[team]!});

  // ---- actions ---------------------------------------------------------

  void _update(VoidCallback change) {
    haptic(ref);
    setState(change);
    _saveDraft();
  }

  void _key(String key) {
    final next = key == 'C' ? '' : applyKey(cards, key, maxDigits: 3);
    // Block values above 162 instead of showing an error afterwards.
    if (!KlaverjasRules.isValidCardsText(next)) return;
    _update(() => cards = next);
  }

  void _confirm() {
    haptic(ref);
    ctx.onSave(
      _entries(),
      complete: true,
      undoDraft: ctx.editing ? null : _draftJson(),
    );
  }

  // ---- build -----------------------------------------------------------

  String _teamLabel(AppLocalizations l10n, String team) =>
      team == KlaverjasRules.wij ? l10n.teamWij : l10n.teamZij;

  String _roemLabel(AppLocalizations l10n, String field) => switch (field) {
    'three' => l10n.roemThree,
    'four' => l10n.roemFour,
    'stuk' => l10n.roemStuk,
    'equal' => l10n.roemFourEqual,
    _ => l10n.roemFourJacks,
  };

  int _roemValue(String field) => config.intSetting(switch (field) {
    'three' => KlaverjasRules.roemThreeKey,
    'four' => KlaverjasRules.roemFourKey,
    'stuk' => KlaverjasRules.roemStukKey,
    'equal' => KlaverjasRules.roemFourEqualKey,
    _ => KlaverjasRules.roemFourJacksKey,
  });

  Widget _bigToggle(
    String label,
    bool selected,
    VoidCallback onTap, {
    String? sub,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        excludeSemantics: true,
        child: SizedBox(
          height: kTouchTarget,
          child: Material(
            color: selected ? scheme.primary : scheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: selected ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 17,
                          height: 1.15,
                          fontWeight: FontWeight.w700,
                          color: selected ? AppTheme.ink : scheme.onSurface,
                        ),
                      ),
                      if (sub != null)
                        Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.15,
                            color: selected
                                ? AppTheme.ink
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _roemRow(AppLocalizations l10n, String team) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(
            _teamLabel(l10n, team),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final f in KlaverjasRules.roemFields) ...[
          Expanded(
            child: Semantics(
              button: true,
              label:
                  '${_teamLabel(l10n, team)} ${_roemLabel(l10n, f)} +${_roemValue(f)}, ${roem[team]![f]}×',
              excludeSemantics: true,
              child: SizedBox(
                height: kTouchTarget,
                child: Material(
                  color: roem[team]![f]! > 0
                      ? scheme.primary
                      : scheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: roem[team]![f]! > 0
                          ? scheme.primary
                          : scheme.outlineVariant,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: pit && team != playing
                        ? null
                        : () => _update(
                            () => roem[team]![f] = (roem[team]![f]! + 1).clamp(
                              0,
                              8,
                            ),
                          ),
                    onLongPress: () => _update(
                      () => roem[team]![f] = (roem[team]![f]! - 1).clamp(0, 8),
                    ),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '+${_roemValue(f)}${roem[team]![f]! > 1 ? ' ×${roem[team]![f]}' : ''}',
                              style: TextStyle(
                                fontFamily: AppTheme.numeralFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                height: 1.1,
                                color: roem[team]![f]! > 0
                                    ? AppTheme.ink
                                    : scheme.onSurface,
                              ),
                            ),
                            Text(
                              _roemLabel(l10n, f),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.1,
                                color: roem[team]![f]! > 0
                                    ? AppTheme.ink
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (f != KlaverjasRules.roemFields.last) const SizedBox(width: 6),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final view = ctx.view;
    final rules = _rules;
    final value = _cardsValue;
    final issue = rules.validateRound(config, _round);
    final canConfirm = issue == null && value != null;
    final outcome = canConfirm ? rules.outcome(config, _round) : null;
    final other = KlaverjasRules.other(playing);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ctx.editing) ...[
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.editRound(number),
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.cancel,
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: ctx.onCancel,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ],
        Row(
          children: [
            for (final t in _teams) ...[
              _bigToggle(
                l10n.teamPlayed(_teamLabel(l10n, t)),
                playing == t,
                () => _update(() => playing = t),
                sub: view.nameOf(t),
              ),
              if (t != _teams.last) const SizedBox(width: kTouchGap),
            ],
          ],
        ),
        const SizedBox(height: kTouchGap),
        Row(
          children: [
            Expanded(
              child: Container(
                height: kTouchTarget,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: pit
                          ? Text(l10n.pitLabel, style: text.titleMedium)
                          : Text(
                              value == null
                                  ? l10n.cardsEmpty
                                  : l10n.cardPointsPair(
                                      _teamLabel(l10n, playing),
                                      value,
                                      _teamLabel(l10n, other),
                                      KlaverjasRules.totalCardPoints - value,
                                    ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: value == null
                                  ? TextStyle(
                                      color: scheme.onSurfaceVariant,
                                      fontSize: 14,
                                    )
                                  : text.titleMedium,
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: kTouchGap),
            Semantics(
              button: true,
              selected: roemPage,
              label: l10n.pageRoem,
              excludeSemantics: true,
              child: SizedBox(
                height: kTouchTarget,
                child: FilterChip(
                  selected: roemPage,
                  showCheckmark: false,
                  label: Text(
                    '${l10n.pageRoem} · ${_roemTotal(KlaverjasRules.wij)} / ${_roemTotal(KlaverjasRules.zij)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onSelected: (_) => _update(() => roemPage = !roemPage),
                ),
              ),
            ),
            const SizedBox(width: kTouchGap),
            Semantics(
              button: true,
              selected: pit,
              label: l10n.pitLabel,
              excludeSemantics: true,
              child: SizedBox(
                height: kTouchTarget,
                child: FilterChip(
                  selected: pit,
                  showCheckmark: false,
                  label: const Text(
                    'Pit',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onSelected: (on) => _update(() {
                    pit = on;
                    if (on) {
                      cards = '';
                      for (final f in KlaverjasRules.roemFields) {
                        roem[other]![f] = 0;
                      }
                    }
                  }),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: kTouchGap),
        if (!roemPage)
          IgnorePointer(
            ignoring: pit,
            child: Opacity(
              opacity: pit ? 0.4 : 1,
              child: WideDigitPad(onKey: _key),
            ),
          )
        else ...[
          _roemRow(l10n, KlaverjasRules.wij),
          const SizedBox(height: kTouchGap),
          _roemRow(l10n, KlaverjasRules.zij),
        ],
        const SizedBox(height: kTouchGap),
        Row(
          children: [
            Expanded(
              child: outcome != null
                  ? LiveScorePreview(
                      scores: [
                        PreviewScore(
                          l10n.teamWij,
                          outcome.points[KlaverjasRules.wij] ?? 0,
                        ),
                        PreviewScore(
                          l10n.teamZij,
                          outcome.points[KlaverjasRules.zij] ?? 0,
                        ),
                      ],
                      badges: [
                        if (outcome.nat) l10n.natShort,
                        if (outcome.pit) l10n.pitShort,
                      ],
                    )
                  : LiveScorePreview(
                      scores: const [],
                      message: value == null
                          ? l10n.cardsEmpty
                          : l10n.issueOutOfRange,
                      messageIsError: false,
                    ),
            ),
            const SizedBox(width: kTouchGap),
            SizedBox(
              width: 148,
              height: kTouchTarget,
              child: FilledButton(
                onPressed: canConfirm ? _confirm : null,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(l10n.saveRound),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
