import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/providers.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/links.dart';
import '../../../core/ui/dialogs.dart';
import '../../games/games_registry.dart';
import '../../pro/entitlement_service.dart';
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
          if (kDebugMode)
            ListTile(
              title: Text(l10n.proDebugOverride),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SegmentedButton<ProOverride>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ProOverride.auto,
                      label: Text(l10n.proDebugAuto),
                    ),
                    ButtonSegment(
                      value: ProOverride.on,
                      label: Text(l10n.proDebugOn),
                    ),
                    ButtonSegment(
                      value: ProOverride.off,
                      label: Text(l10n.proDebugOff),
                    ),
                  ],
                  selected: {prefs.proOverride},
                  onSelectionChanged: (v) => ref
                      .read(entitlementProvider.notifier)
                      .setOverride(v.first),
                ),
              ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              l10n.aboutSection,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacyPolicy),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => openLink(context, AppLinks.privacy),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.termsOfUse),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () => openLink(context, AppLinks.terms),
          ),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: Text(l10n.contactLabel),
            subtitle: const Text(AppLinks.contactEmail),
            onTap: () => openLink(context, AppLinks.contact),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.appVersion),
            subtitle: const _AppVersion(),
          ),
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

class _AppVersion extends StatelessWidget {
  const _AppVersion();

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (_, snap) => Text(snap.hasData
            ? '${snap.data!.version} (${snap.data!.buildNumber})'
            : ''),
      );
}
