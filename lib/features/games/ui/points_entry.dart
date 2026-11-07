import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../data/game_state.dart';
import '../rules/game_rules.dart';

/// Generic entry: one signed whole number per participant.
class PointsEntry extends StatefulWidget {
  const PointsEntry({
    super.key,
    required this.view,
    required this.existing,
    required this.onSubmit,
  });

  final GameView view;
  final Entries? existing;
  final void Function(Entries entries) onSubmit;

  @override
  State<PointsEntry> createState() => _PointsEntryState();
}

class _PointsEntryState extends State<PointsEntry> {
  late final Map<String, TextEditingController> _controllers = {
    for (final p in widget.view.config.participants)
      p: TextEditingController(
        text: widget.existing?[p]?['points']?.toString() ?? '',
      ),
  };

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _submit() {
    final entries = <String, Entry>{};
    for (final e in _controllers.entries) {
      final v = int.tryParse(e.value.text.trim());
      if (v != null) entries[e.key] = {'points': v};
    }
    widget.onSubmit(entries);
  }

  @override
  Widget build(BuildContext context) {
    final ids = widget.view.config.participants;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (var i = 0; i < ids.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: TextField(
                    controller: _controllers[ids[i]],
                    autofocus: i == 0,
                    keyboardType:
                        const TextInputType.numberWithOptions(signed: true),
                    textInputAction:
                        i == ids.length - 1 ? TextInputAction.done : TextInputAction.next,
                    onSubmitted: (_) => i == ids.length - 1 ? _submit() : null,
                    style: const TextStyle(fontSize: 24),
                    decoration: InputDecoration(
                      labelText: widget.view.nameOf(ids[i]),
                      hintText: context.l10n.points,
                    ),
                  ),
                ),
            ],
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _submit,
              child: Text(context.l10n.saveRound),
            ),
          ),
        ),
      ],
    );
  }
}
