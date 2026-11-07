import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../../games/games_registry.dart';
import '../../purchase/entitlements.dart';
import '../../purchase/purchase_service.dart';
import '../data/settings_repository.dart';
import 'settings_editor.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final prefs = ref.watch(prefsProvider);
    final repo = ref.read(settingsRepositoryProvider);
    final service = ref.read(purchaseServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            title: Text(l10n.theme),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(value: ThemeMode.system, label: Text(l10n.themeSystem)),
                  ButtonSegment(value: ThemeMode.light, label: Text(l10n.themeLight)),
                  ButtonSegment(value: ThemeMode.dark, label: Text(l10n.themeDark)),
                ],
                selected: {prefs.themeMode},
                onSelectionChanged: (s) => repo.set('theme', s.first.name),
              ),
            ),
          ),
          SwitchListTile(
            title: Text(l10n.haptics),
            value: prefs.haptics,
            onChanged: (v) => repo.set('haptics', v ? '1' : '0'),
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
          if (kDebugMode && service is FakePurchaseService)
            SwitchListTile(
              title: Text(l10n.debugUnlock),
              value: ref.watch(entitlementsProvider).isUnlocked,
              onChanged: service.setUnlocked,
            ),
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
