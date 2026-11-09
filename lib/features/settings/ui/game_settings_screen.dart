import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/content_width.dart';
import '../../../core/ui/suits.dart';
import '../../games/games_registry.dart';
import '../data/settings_repository.dart';
import 'game_settings_summary.dart';
import 'settings_editor.dart';

/// Which game panel is open. Kept for the session, so coming back to the
/// screen shows the panel you used last.
class OpenGamePanel extends Notifier<String?> {
  @override
  String? build() => null;

  void toggle(String type) => state = state == type ? null : type;
}

final openGamePanelProvider = NotifierProvider<OpenGamePanel, String?>(
  OpenGamePanel.new,
);

/// Default rule options per game, used for new games: one accordion panel per
/// game, at most one open.
class GameSettingsScreen extends ConsumerWidget {
  const GameSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(prefsProvider);
    final repo = ref.read(settingsRepositoryProvider);
    final open = ref.watch(openGamePanelProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.gameSettingsTitle)),
      body: ListView(
        padding: contentPadding(context, const EdgeInsets.fromLTRB(16, 8, 16, 24)),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.gameSettingsIntro,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          for (final entry in gameDefinitions.entries)
            if (entry.value.rules.settingSpecs.isNotEmpty)
              _GamePanel(
                key: ValueKey(entry.key),
                def: entry.value,
                isOpen: open == entry.key,
                onToggle: () =>
                    ref.read(openGamePanelProvider.notifier).toggle(entry.key),
                values: prefs.ruleOptions(entry.value.rules),
                onChanged: (k, v) => repo.setRuleOption(
                  entry.value.rules,
                  prefs.ruleOptions(entry.value.rules),
                  k,
                  v,
                ),
                onRestore: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final previous = await repo.resetRuleOptions(
                    entry.value.rules,
                  );
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(l10n.restoreDefaultsDone),
                        action: SnackBarAction(
                          label: l10n.undoAction,
                          onPressed: () => repo.restoreRuleOptions(
                            entry.value.rules,
                            previous,
                          ),
                        ),
                      ),
                    );
                },
              ),
        ],
      ),
    );
  }
}

class _GamePanel extends StatelessWidget {
  const _GamePanel({
    super.key,
    required this.def,
    required this.isOpen,
    required this.onToggle,
    required this.values,
    required this.onChanged,
    required this.onRestore,
  });

  final GameDefinition def;
  final bool isOpen;
  final VoidCallback onToggle;
  final Map<String, Object?> values;
  final void Function(String key, Object? value) onChanged;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final isDefault = _sameAsDefaults();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: isOpen,
            child: InkWell(
              onTap: onToggle,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      SuitPip(def.suit, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(def.name(l10n), style: text.titleMedium),
                            Text(
                              gameSettingsSummary(
                                l10n,
                                def.rules.type,
                                values,
                              ),
                              style: text.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: isOpen ? 0.5 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(Icons.expand_more),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: isOpen
                ? Column(
                    children: [
                      const Divider(height: 1),
                      SettingsEditor(
                        rules: def.rules,
                        values: values,
                        onChanged: onChanged,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: TextButton(
                            onPressed: isDefault ? null : onRestore,
                            child: Text(l10n.restoreDefaults),
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  bool _sameAsDefaults() {
    final defaults = def.rules.defaultSettings;
    return defaults.entries.every((e) => values[e.key] == e.value);
  }
}
