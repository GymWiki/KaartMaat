import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../settings/data/settings_repository.dart';
import '../data/game_state.dart';
import '../rules/game_rules.dart';
import '../rules/hearts_rules.dart';

/// Penalty counter per player: +1 for a heart, a button for the queen of
/// spades and a button for "de maan schieten". Shows how many of the points
/// of this deal have been handed out.
class HeartsEntry extends ConsumerStatefulWidget {
  const HeartsEntry({
    super.key,
    required this.view,
    required this.existing,
    required this.onSubmit,
  });

  final GameView view;
  final Entries? existing;
  final void Function(Entries entries) onSubmit;

  @override
  ConsumerState<HeartsEntry> createState() => _HeartsEntryState();
}

class _HeartsEntryState extends ConsumerState<HeartsEntry> {
  static const _rules = HeartsRules();
  late final GameConfig _config = widget.view.config;
  late final int _total = _config.intSetting(HeartsRules.totalPointsKey);
  late final int _queen = _config.intSetting(HeartsRules.queenPointsKey);
  late final bool _moonEnabled = _config.boolSetting(
    HeartsRules.moonEnabledKey,
  );

  late final Map<String, int> _points = {
    for (final p in _config.participants)
      p: (widget.existing?[p]?['points'] as int?) ?? 0,
  };
  String? _moon;

  @override
  void initState() {
    super.initState();
    for (final p in _config.participants) {
      if (widget.existing?[p]?['moon'] == true) _moon = p;
    }
  }

  Entries _entries() => {
    for (final p in _config.participants)
      p: {'points': _points[p], 'moon': p == _moon},
  };

  void _add(String p, int delta) {
    haptic(ref);
    setState(() {
      _moon = null;
      _points[p] = (_points[p]! + delta).clamp(0, _total);
    });
  }

  void _toggleMoon(String p) {
    haptic(ref);
    setState(() {
      if (_moon == p) {
        _moon = null;
        for (final q in _config.participants) {
          _points[q] = 0;
        }
      } else {
        _moon = p;
        _points.addAll(_rules.moonPoints(_config, p));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final entries = _entries();
    final issue = _rules.validateRound(
      _config,
      RoundData(number: 1, entries: entries),
    );
    final handedOut = _points.values.fold(0, (a, b) => a + b);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              for (final p in _config.participants)
                Card(
                  color: _moon == p ? scheme.tertiaryContainer : null,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.view.nameOf(p),
                                style: text.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${_points[p]}',
                              style: text.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _btn('−1', () => _add(p, -1)),
                            _btn('+1', () => _add(p, 1)),
                            _btn(
                              l10n.heartsQueen(_queen),
                              () => _add(p, _queen),
                            ),
                            if (_moonEnabled)
                              FilledButton.tonal(
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(64, 48),
                                  backgroundColor: _moon == p
                                      ? scheme.tertiary
                                      : null,
                                  foregroundColor: _moon == p
                                      ? scheme.onTertiary
                                      : null,
                                ),
                                onPressed: () => _toggleMoon(p),
                                child: Text(l10n.heartsMoon),
                              ),
                          ],
                        ),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _moon != null
                      ? l10n.heartsMoonShot
                      : l10n.heartsHandedOut(handedOut, _total),
                  style: text.titleMedium?.copyWith(
                    color: issue != null && _moon == null ? scheme.error : null,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: issue == null
                        ? () => widget.onSubmit(entries)
                        : null,
                    child: Text(l10n.saveRound),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _btn(String label, VoidCallback onTap) => FilledButton.tonal(
    style: FilledButton.styleFrom(minimumSize: const Size(64, 48)),
    onPressed: onTap,
    child: Text(label, style: const TextStyle(fontSize: 18)),
  );
}
