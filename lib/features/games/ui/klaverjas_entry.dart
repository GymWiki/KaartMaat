import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/big_number_pad.dart';
import '../../settings/data/settings_repository.dart';
import '../data/game_state.dart';
import '../rules/game_rules.dart';
import '../rules/klaverjas_rules.dart';

/// One deal: who played, card points of the playing team (the other team gets
/// 162 minus that), roem per team via quick buttons, optional pit. Nat is
/// worked out automatically and shown in the preview.
class KlaverjasEntry extends ConsumerStatefulWidget {
  const KlaverjasEntry({
    super.key,
    required this.view,
    required this.existing,
    required this.onSubmit,
  });

  final GameView view;
  final Entries? existing;
  final void Function(Entries entries) onSubmit;

  @override
  ConsumerState<KlaverjasEntry> createState() => _KlaverjasEntryState();
}

class _KlaverjasEntryState extends ConsumerState<KlaverjasEntry> {
  static const _rules = KlaverjasRules();
  late final GameConfig _config = widget.view.config;

  String? _playing;
  bool _pit = false;
  String _cards = '';
  final Map<String, Map<String, int>> _roem = {
    for (final t in const [KlaverjasRules.wij, KlaverjasRules.zij])
      t: {for (final f in KlaverjasRules.roemFields) f: 0},
  };

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e == null) return;
    for (final t in const [KlaverjasRules.wij, KlaverjasRules.zij]) {
      if (e[t]?['playing'] == true) {
        _playing = t;
        _pit = e[t]?['pit'] == true;
        _cards = '${e[t]?['cards'] ?? ''}';
      }
      for (final f in KlaverjasRules.roemFields) {
        _roem[t]![f] = (e[t]?[f] as int?) ?? 0;
      }
    }
  }

  Entries _entries() {
    final playing = _playing;
    final cards = _pit ? KlaverjasRules.totalCardPoints : int.tryParse(_cards);
    return {
      for (final t in const [KlaverjasRules.wij, KlaverjasRules.zij])
        t: {
          'playing': t == playing,
          'pit': _pit && t == playing,
          if (cards != null)
            'cards': t == playing ? cards : KlaverjasRules.totalCardPoints - cards,
          ..._roem[t]!,
        },
    };
  }

  void _key(String key) {
    haptic(ref);
    setState(() => _cards = applyKey(_cards, key, maxDigits: 3));
  }

  void _roemTap(String team, String field, int delta) {
    haptic(ref);
    setState(() {
      final next = (_roem[team]![field]! + delta).clamp(0, 8);
      _roem[team]![field] = next;
    });
  }

  String _teamLabel(AppLocalizations l10n, String team) =>
      team == KlaverjasRules.wij ? l10n.teamWij : l10n.teamZij;

  String _roemLabel(AppLocalizations l10n, String field) => switch (field) {
        'three' => l10n.roemThree,
        'four' => l10n.roemFour,
        'stuk' => l10n.roemStuk,
        'equal' => l10n.roemFourEqual,
        _ => l10n.roemFourJacks,
      };

  int _roemValue(String field) => _config.intSetting(switch (field) {
        'three' => KlaverjasRules.roemThreeKey,
        'four' => KlaverjasRules.roemFourKey,
        'stuk' => KlaverjasRules.roemStukKey,
        'equal' => KlaverjasRules.roemFourEqualKey,
        _ => KlaverjasRules.roemFourJacksKey,
      });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final entries = _entries();
    final issue = _rules.validateRound(_config, RoundData(number: 1, entries: entries));
    final outcome = _rules.outcome(_config, RoundData(number: 1, entries: entries));
    final cards = int.tryParse(_cards);
    final hint = _playing == null
        ? l10n.choosePlaying
        : (!_pit && cards == null)
            ? l10n.cardsEmpty
            : (issue != null ? l10n.issueOutOfRange : null);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(l10n.playingTeam, style: text.titleMedium),
              const SizedBox(height: 8),
              Row(children: [
                for (final t in const [KlaverjasRules.wij, KlaverjasRules.zij])
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        showCheckmark: false,
                        selected: _playing == t,
                        onSelected: (_) {
                          haptic(ref);
                          setState(() => _playing = t);
                        },
                        label: SizedBox(
                          width: double.infinity,
                          child: Column(children: [
                            Text(_teamLabel(l10n, t),
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold)),
                            Text(widget.view.nameOf(t),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13)),
                          ]),
                        ),
                      ),
                    ),
                  ),
              ]),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.pitLabel),
                value: _pit,
                onChanged: (v) => setState(() {
                  _pit = v;
                  if (v) {
                    for (final f in KlaverjasRules.roemFields) {
                      final other = _playing == null
                          ? null
                          : KlaverjasRules.other(_playing!);
                      if (other != null) _roem[other]![f] = 0;
                    }
                  }
                }),
              ),
              if (!_pit) ...[
                Text(
                  l10n.cardPointsLine(
                    cards ?? 0,
                    cards == null ? 0 : KlaverjasRules.totalCardPoints - cards,
                  ),
                  style: text.titleMedium,
                ),
                const SizedBox(height: 8),
                BigNumberPad(onKey: _key, allowNegative: false),
              ],
              const SizedBox(height: 8),
              Text(l10n.roemTitle, style: text.titleMedium),
              Text(l10n.roemHint, style: text.bodySmall),
              const SizedBox(height: 8),
              for (final t in const [KlaverjasRules.wij, KlaverjasRules.zij])
                if (!(_pit && _playing != null && t != _playing))
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(_teamLabel(l10n, t), style: text.titleMedium),
                            const Spacer(),
                            Text(
                              l10n.roemTotal(_rules.roemOf(_config, _roem[t])),
                              style: text.titleMedium,
                            ),
                          ]),
                          const SizedBox(height: 8),
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final f in KlaverjasRules.roemFields)
                              GestureDetector(
                                onLongPress: () => _roemTap(t, f, -1),
                                child: ActionChip(
                                  label: Text(
                                    '${_roemLabel(l10n, f)} +${_roemValue(f)}'
                                    '${_roem[t]![f]! > 0 ? '  ×${_roem[t]![f]}' : ''}',
                                  ),
                                  backgroundColor: _roem[t]![f]! > 0
                                      ? scheme.primaryContainer
                                      : null,
                                  onPressed: () => _roemTap(t, f, 1),
                                ),
                              ),
                          ]),
                        ],
                      ),
                    ),
                  ),
              Card(
                color: scheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${l10n.teamWij}: ${outcome.points['wij']}  ·  '
                        '${l10n.teamZij}: ${outcome.points['zij']}',
                        style: text.headlineSmall,
                      ),
                      if (outcome.nat)
                        Text(l10n.natExplain,
                            style: TextStyle(
                                color: scheme.error, fontWeight: FontWeight.w600)),
                      if (outcome.pit) Text(l10n.pitExplain),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              if (hint != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(hint, style: TextStyle(color: scheme.error)),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: issue == null ? () => widget.onSubmit(entries) : null,
                  child: Text(l10n.saveRound),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
