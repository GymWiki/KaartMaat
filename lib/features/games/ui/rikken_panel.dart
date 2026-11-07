import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/live_score_preview.dart';
import '../../../core/ui/player_selector.dart';
import '../../../core/ui/touch.dart';
import '../../settings/data/settings_repository.dart';
import '../rules/game_rules.dart';
import '../rules/rikken_rules.dart';
import 'panel_context.dart';
import 'rikken_labels.dart';

enum _Step { contract, bidder, partner, result }

/// Rikken input on the game screen, one step at a time in the same panel:
/// contract grid, bidder, partner (only when the contract has one), then
/// "gehaald / niet gehaald" with a stepper for over- or undertricks. A row of
/// crumbs on top shows what is chosen and jumps back to any step. The points
/// of all four players and the zero-sum check are always visible.
class RikkenPanel extends ConsumerStatefulWidget {
  const RikkenPanel({super.key, required this.ctx});
  final PanelContext ctx;

  @override
  ConsumerState<RikkenPanel> createState() => _RikkenPanelState();
}

class _RikkenPanelState extends ConsumerState<RikkenPanel> {
  static const _rules = RikkenRules();

  PanelContext get ctx => widget.ctx;
  late final GameConfig config = ctx.view.config;
  late final int number = ctx.roundNumber;
  late final List<String> ids = config.participants;

  String? contractId;
  String? bidder;
  String? partner;
  bool success = true;
  int diff = 0;
  _Step step = _Step.contract;

  RikContract? get contract =>
      contractId == null ? null : RikkenRules.contractOf(contractId!);

  @override
  void initState() {
    super.initState();
    final initial = ctx.initialDraft;
    final usable =
        initial != null &&
        initial['round'] == number &&
        initial['editing'] == ctx.editing;
    if (usable) {
      contractId = initial['contract'] as String?;
      bidder = initial['bidder'] as String?;
      partner = initial['partner'] as String?;
      success = initial['success'] != false;
      diff = initial['diff'] as int? ?? 0;
      step = _Step.values.firstWhere(
        (s) => s.name == initial['step'],
        orElse: () => _Step.contract,
      );
    } else if (ctx.existing != null) {
      for (final p in ids) {
        final e = ctx.existing![p];
        if (e?['role'] == 'bidder') {
          bidder = p;
          contractId = e?['contract'] as String?;
          final tricks = e?['tricks'];
          final c = contract;
          if (c != null && tricks is int) {
            success = RikkenRules.madeWith(c, tricks);
            diff = RikkenRules.diffFor(c, tricks);
          }
        }
        if (e?['role'] == 'partner') partner = p;
      }
      step = _Step.result;
    } else {
      // A table tends to repeat its contract: preselect it and ask who bids.
      final previous = ctx.view.state.rounds
          .where((r) => r.number < number)
          .toList();
      contractId = _rules.defaultContract(config, previous);
      step = previous.isEmpty ? _Step.contract : _Step.bidder;
    }
  }

  // ---- derived ---------------------------------------------------------

  bool get _complete {
    final c = contract;
    return c != null && bidder != null && (!c.partner || partner != null);
  }

  Entries _entries() {
    final c = contract;
    final tricks = c == null
        ? null
        : RikkenRules.tricksFor(c, success: success, diff: diff);
    return {
      for (final p in ids)
        p: {
          'role': p == bidder
              ? 'bidder'
              : (p == partner && (c?.partner ?? false))
              ? 'partner'
              : 'opp',
          'contract': contractId,
          'tricks': tricks,
        },
    };
  }

  RoundData get _round => RoundData(number: number, entries: _entries());

  Map<String, Object?> _draftJson() => {
    'round': number,
    'editing': ctx.editing,
    'step': step.name,
    'contract': contractId,
    'bidder': bidder,
    'partner': partner,
    'success': success,
    'diff': diff,
  };

  void _update(VoidCallback change) {
    haptic(ref);
    setState(change);
    ctx.draft.schedule(_draftJson());
  }

  // ---- actions ---------------------------------------------------------

  void _pickContract(RikContract c) => _update(() {
    contractId = c.id;
    if (!c.partner) partner = null;
    diff = diff.clamp(
      RikkenRules.minDiff(success: success),
      RikkenRules.maxDiff(c, success: success),
    );
    step = _Step.bidder;
  });

  void _pickBidder(String p) => _update(() {
    bidder = p;
    if (partner == p) partner = null;
    step = (contract?.partner ?? false) && partner == null
        ? _Step.partner
        : _Step.result;
  });

  void _pickPartner(String p) => _update(() {
    partner = p;
    step = _Step.result;
  });

  void _setSuccess(bool value) => _update(() {
    success = value;
    final c = contract;
    diff = c == null
        ? 0
        : diff.clamp(
            RikkenRules.minDiff(success: value),
            RikkenRules.maxDiff(c, success: value),
          );
    if (c != null && c.type == RikType.atLeast && !value && diff < 1) diff = 1;
  });

  void _stepDiff(int delta) {
    final c = contract;
    if (c == null) return;
    _update(
      () => diff = (diff + delta).clamp(
        RikkenRules.minDiff(success: success),
        RikkenRules.maxDiff(c, success: success),
      ),
    );
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

  Widget _crumb(String label, _Step target, {required bool filled}) {
    final scheme = Theme.of(context).colorScheme;
    final active = step == target;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: active ? scheme.primary : scheme.surfaceContainerHighest,
        shape: StadiumBorder(
          side: BorderSide(
            color: active ? scheme.primary : scheme.outlineVariant,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => _update(() => step = target),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, maxWidth: 150),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: filled ? FontWeight.w700 : FontWeight.w500,
                    color: active
                        ? AppTheme.ink
                        : filled
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _contractGrid(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    const columns = 5;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - kTouchGap * (columns - 1)) / columns;
        return Wrap(
          spacing: kTouchGap,
          runSpacing: kTouchGap,
          children: [
            for (final c in rikContracts)
              Semantics(
                button: true,
                selected: c.id == contractId,
                label: rikContractName(l10n, c.id),
                excludeSemantics: true,
                child: SizedBox(
                  width: width,
                  height: kTouchTarget,
                  child: Material(
                    color: c.id == contractId
                        ? scheme.primary
                        : scheme.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: c.id == contractId
                            ? scheme.primary
                            : scheme.outlineVariant,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _pickContract(c),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: Center(
                          child: Text(
                            rikContractShort(l10n, c.id),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.1,
                              fontWeight: FontWeight.w700,
                              color: c.id == contractId
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
          ],
        );
      },
    );
  }

  Widget _namePicker(
    List<String> options,
    String? selected,
    ValueChanged<String> onPick,
  ) => PlayerSelector(
    chips: [for (final p in options) PlayerChipData(label: ctx.view.nameOf(p))],
    selectedIndex: selected == null ? -1 : options.indexOf(selected),
    onSelected: (i) => onPick(options[i]),
  );

  Widget _bigToggle(String label, bool selected, VoidCallback onTap) {
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
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppTheme.ink : scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultStep(AppLocalizations l10n) {
    final c = contract;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _bigToggle(l10n.rikMade, success, () => _setSuccess(true)),
            const SizedBox(width: kTouchGap),
            _bigToggle(l10n.rikFailed, !success, () => _setSuccess(false)),
          ],
        ),
        if (c != null && c.type == RikType.atLeast) ...[
          const SizedBox(height: kTouchGap),
          Row(
            children: [
              Expanded(
                child: Text(
                  success ? l10n.rikOvertricks : l10n.rikUndertricks,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              ),
              SizedBox(
                width: kTouchTarget,
                height: kTouchTarget,
                child: Semantics(
                  button: true,
                  label: l10n.rikFewer,
                  excludeSemantics: true,
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(kTouchTarget, kTouchTarget),
                    ),
                    onPressed: diff > RikkenRules.minDiff(success: success)
                        ? () => _stepDiff(-1)
                        : null,
                    child: const Icon(Icons.remove),
                  ),
                ),
              ),
              SizedBox(
                width: 56,
                child: Center(child: Text('$diff', style: text.headlineMedium)),
              ),
              SizedBox(
                width: kTouchTarget,
                height: kTouchTarget,
                child: Semantics(
                  button: true,
                  label: l10n.rikMore,
                  excludeSemantics: true,
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(kTouchTarget, kTouchTarget),
                    ),
                    onPressed: diff < RikkenRules.maxDiff(c, success: success)
                        ? () => _stepDiff(1)
                        : null,
                    child: const Icon(Icons.add),
                  ),
                ),
              ),
            ],
          ),
        ] else if (c != null) ...[
          const SizedBox(height: kTouchGap),
          Text(
            l10n.rikExactNote(c.target),
            style: TextStyle(color: scheme.onSurfaceVariant),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final view = ctx.view;
    final c = contract;
    final issue = _rules.validateRound(config, _round);
    final ready = _complete && issue == null;
    final outcome = ready ? _rules.outcome(config, _round) : null;

    final content = switch (step) {
      _Step.contract => _contractGrid(l10n),
      _Step.bidder => _namePicker(ids, bidder, _pickBidder),
      _Step.partner => _namePicker(
        [
          for (final p in ids)
            if (p != bidder) p,
        ],
        partner,
        _pickPartner,
      ),
      _Step.result => _resultStep(l10n),
    };

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
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _crumb(
              c == null ? l10n.rikContract : rikContractShort(l10n, c.id),
              _Step.contract,
              filled: c != null,
            ),
            _crumb(
              bidder == null ? l10n.rikBidder : view.nameOf(bidder!),
              _Step.bidder,
              filled: bidder != null,
            ),
            if (c?.partner ?? false)
              _crumb(
                partner == null
                    ? l10n.rikPartner
                    : l10n.rikPartnerCrumb(view.nameOf(partner!)),
                _Step.partner,
                filled: partner != null,
              ),
            _crumb(
              _complete
                  ? (success ? l10n.rikMade : l10n.rikFailed)
                  : l10n.rikResultCrumb,
              _Step.result,
              filled: _complete,
            ),
          ],
        ),
        const SizedBox(height: kTouchGap),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 124),
          child: Align(alignment: Alignment.topCenter, child: content),
        ),
        const SizedBox(height: kTouchGap),
        Row(
          children: [
            Expanded(
              child: outcome != null
                  ? LiveScorePreview(
                      scores: [
                        for (final p in ids)
                          PreviewScore(view.nameOf(p), outcome.points[p] ?? 0),
                      ],
                      sum: outcome.sum,
                    )
                  : LiveScorePreview(
                      scores: const [],
                      message: bidder == null
                          ? l10n.rikChooseBidder
                          : (c?.partner ?? false) && partner == null
                          ? l10n.rikChoosePartner
                          : l10n.rikChooseContract,
                      messageIsError: false,
                    ),
            ),
            const SizedBox(width: kTouchGap),
            SizedBox(
              width: 148,
              height: kTouchTarget,
              child: FilledButton(
                onPressed: ready ? _confirm : null,
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
