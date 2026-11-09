import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../../games/games_registry.dart';
import '../data/settings_repository.dart';
import 'settings_editor.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(prefsProvider);
    final repo = ref.read(settingsRepositoryProvider);
    final themeLabels = {
      ThemeChoice.system: l10n.themeSystem,
      ThemeChoice.light: l10n.themeLight,
      ThemeChoice.dark: l10n.themeDark,
      ThemeChoice.oled: l10n.themeOled,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            title: Text(l10n.theme),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in ThemeChoice.values)
                    ChoiceChip(
                      label: Text(themeLabels[c]!),
                      selected: prefs.themeChoice == c,
                      onSelected: (_) => repo.set('theme', c.name),
                    ),
                ],
              ),
            ),
          ),
          SwitchListTile(
            title: Text(l10n.haptics),
            value: prefs.haptics,
            onChanged: (v) => repo.set('haptics', v ? '1' : '0'),
          ),
          SwitchListTile(
            title: Text(l10n.settingKeepAwake),
            value: prefs.keepAwakeByDefault,
            onChanged: (v) => repo.set('keepAwake', v ? '1' : '0'),
          ),
          for (final def in gameDefinitions.values)
            if (def.rules.settingSpecs.isNotEmpty) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text('${l10n.rulesSection}: ${def.name(l10n)}',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              SettingsEditor(
                rules: def.rules,
                values: prefs.ruleOptions(def.rules),
                onChanged: (k, v) => repo.setRuleOption(
                    def.rules, prefs.ruleOptions(def.rules), k, v),
              ),
            ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_forever),
            title: Text(l10n.resetData),
            onTap: () async {
              if (await confirmDialog(context, l10n.resetConfirm,
                  actionLabel: l10n.delete)) {
                await ref.read(databaseProvider).resetAll();
                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(l10n.resetDone)));
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
