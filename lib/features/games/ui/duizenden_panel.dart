import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/big_number_pad.dart' show applyKey;
import '../../../core/ui/player_selector.dart';
import '../../../core/ui/touch.dart';
import '../../../core/ui/wide_digit_pad.dart';
import '../../settings/data/settings_repository.dart';
import '../rules/duizenden_rules.dart';
import '../rules/game_rules.dart';
import 'panel_context.dart';

/// Duizenden input on the game screen: one score per player, typed on the
/// number pad (with a sign key for negative rounds). Tap a player to type
/// their score, "Volgende" moves on to the next player without one. Every
/// player's chip shows what the total becomes, and an accent border for
/// whoever would reach the target. "Ronde opslaan" needs a score for
/// everybody (0 counts, empty does not) and nothing outside the allowed range.
class DuizendenPanel extends ConsumerStatefulWidget {
  const DuizendenPanel({super.key, required this.ctx});
  final PanelContext ctx;

  @override
  ConsumerState<DuizendenPanel> createState() => _DuizendenPanelState();
}

class _DuizendenPanelState extends ConsumerState<DuizendenPanel> {
  static const _rules = DuizendenRules();

  PanelContext get ctx => widget.ctx;
  late final GameConfig config = ctx.view.config;
  late final int number = ctx.roundNumber;
  late final List<String> ids = config.participants;
  late final int target = config.intSetting(DuizendenRules.targetScoreKey);
  late final int lo = _rules.minEntry(config);
  late final int hi = _rules.maxEntry(config);
  late final int maxDigits = _rules.maxDigits(config);

  /// What is typed per player ("-", "-12", "340", ...).
  final Map<String, String> typed = {};
  int focus = 0;

  /// Totals before this round (an earlier round being corrected is left out).
  late final Map<String, int> base = _rules.totals(config, [
    for (final r in ctx.view.state.rounds)
      if (r.number != number) r,
  ]);

  @override
  void initState() {
    super.initState();
    for (final p in ids) {
      typed[p] = '';
    }
    final initial = ctx.initialDraft;
    final usable =
        initial != null &&
        initial['round'] == number &&
        initial['editing'] == ctx.editing;
    if (usable) {
      final saved = initial['values'];
      if (saved is Map) {
        for (final p in ids) {
          final v = saved[p];
          typed[p] = v is String ? v : '';
        }
      }
      focus = (initial['focus'] as int? ?? 0).clamp(0, ids.length - 1);
    } else if (ctx.existing != null) {
      for (final p in ids) {
        final v = ctx.existing![p]?['points'];
        typed[p] = v is int ? '$v' : '';
      }
    }
  }

  // ---- derived ---------------------------------------------------------

  int? _value(String p) => int.tryParse(typed[p] ?? '');

  bool _outOfRange(String p) {
    final v = _value(p);
    return v != null && (v < lo || v > hi);
  }

  int? _newTotal(String p) {
    final v = _value(p);
    return v == null ? null : (base[p] ?? 0) + v;
  }

  bool _reaches(String p) {
    final t = _newTotal(p);
    return target > 0 && t != null && t >= target;
  }

  Entries? get _entries {
    final result = <String, Entry>{};
    for (final p in ids) {
      final v = _value(p);
      if (v == null) return null;
      result[p] = {'points': v};
    }
    return result;
  }

  bool get _canSave {
    final e = _entries;
    return e != null &&
        _rules.validateRound(config, RoundData(number: number, entries: e)) ==
            null;
  }

  Map<String, Object?> _draftJson() => {
    'round': number,
    'editing': ctx.editing,
    'values': typed,
    'focus': focus,
  };

  void _changed() => ctx.draft.schedule(_draftJson());

  // ---- actions ---------------------------------------------------------

  void _key(String key) {
    final p = ids[focus];
    setState(() {
      var next = applyKey(typed[p] ?? '', key, maxDigits: maxDigits);
      if (next == '-0') next = '0';
      typed[p] = next;
    });
    _changed();
  }

  void _next() {
    haptic(ref);
    setState(() {
      final filled = [for (final p in ids) _value(p) != null];
      focus =
          PlayerSelector.nextUnfilled(filled, focus) ??
          (focus + 1) % ids.length;
    });
    _changed();
  }

  void _save() {
    final entries = _entries;
    if (entries == null || !_canSave) return;
    haptic(ref);
    ctx.onSave(
      entries,
      complete: true,
      undoDraft: ctx.editing ? null : _draftJson(),
    );
  }

  // ---- build -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final view = ctx.view;
    final current = ids[focus];
    final anyOutOfRange = ids.any(_outOfRange);
    final reaching = [
      for (final p in ids)
        if (_reaches(p)) view.nameOf(p),
    ];
    final currentFilled = _value(current) != null && !_outOfRange(current);

    String? message;
    bool messageIsError = false;
    if (anyOutOfRange) {
      message = l10n.duizendenOutOfRange(lo, hi);
      messageIsError = true;
    } else if (reaching.isNotEmpty) {
      message = l10n.duizendenReaches(reaching.join(', '));
    } else if (_entries == null) {
      message = l10n.duizendenFillAll;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ctx.editing)
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
        PlayerSelector(
          chips: [
            for (final p in ids)
              PlayerChipData(
                label: view.nameOf(p),
                value: (typed[p] ?? '').isEmpty ? null : typed[p],
                done: _value(p) != null && !_outOfRange(p),
                caption: _newTotal(p) != null
                    ? '→ ${_newTotal(p)}'
                    : '${base[p] ?? 0}',
                highlight: _reaches(p) && !_outOfRange(p),
                error: _outOfRange(p),
              ),
          ],
          selectedIndex: focus,
          onSelected: (i) {
            haptic(ref);
            setState(() => focus = i);
            _changed();
          },
        ),
        const SizedBox(height: kTouchGap),
        WideDigitPad(onKey: _key, signKey: true),
        const SizedBox(height: kTouchGap),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: kTouchTarget,
                child: OutlinedButton(
                  onPressed: currentFilled ? _next : null,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(l10n.next),
                  ),
                ),
              ),
            ),
            const SizedBox(width: kTouchGap),
            Expanded(
              flex: 3,
              child: SizedBox(
                height: kTouchTarget,
                child: FilledButton(
                  onPressed: _canSave ? _save : null,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(l10n.saveRoundShort),
                  ),
                ),
              ),
            ),
          ],
        ),
        // A line of fixed height, so the keys never move under the thumb when
        // a hint appears or goes away.
        const SizedBox(height: 6),
        SizedBox(
          height: 18,
          child: message == null
              ? null
              : Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodySmall?.copyWith(
                    color: messageIsError
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                  ),
                ),
        ),
      ],
    );
  }
}
