import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../games/games_registry.dart';
import '../data/settings_repository.dart';
import 'settings_editor.dart';

/// Default rule options per game, used for new games.
class GameSettingsScreen extends ConsumerWidget {
  const GameSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(prefsProvider);
    final repo = ref.read(settingsRepositoryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.gameSettingsTitle)),
      body: ListView(
        children: [
          for (final def in gameDefinitions.values)
            if (def.rules.settingSpecs.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  def.name(l10n),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              SettingsEditor(
                rules: def.rules,
                values: prefs.ruleOptions(def.rules),
                onChanged: (k, v) => repo.setRuleOption(
                  def.rules,
                  prefs.ruleOptions(def.rules),
                  k,
                  v,
                ),
              ),
            ],
        ],
      ),
    );
  }
}
