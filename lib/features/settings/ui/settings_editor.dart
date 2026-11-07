import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../../games/rules/custom_rules.dart';
import '../../games/rules/game_rules.dart';

String settingLabel(AppLocalizations l10n, String key) => switch (key) {
      CustomRules.targetScoreKey => l10n.settingTargetScore,
      CustomRules.lowestWinsKey => l10n.settingLowestWins,
      _ => key,
    };

/// Renders the rule options of one game from its [SettingSpec]s.
class SettingsEditor extends StatelessWidget {
  const SettingsEditor({
    super.key,
    required this.rules,
    required this.values,
    required this.onChanged,
  });

  final GameRules rules;
  final Map<String, Object?> values;
  final void Function(String key, Object? value) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      children: [
        for (final spec in rules.settingSpecs)
          switch (spec.kind) {
            SettingKind.boolean => SwitchListTile(
                title: Text(settingLabel(l10n, spec.key)),
                value: values[spec.key] == true,
                onChanged: (v) => onChanged(spec.key, v),
              ),
            SettingKind.integer => ListTile(
                title: Text(settingLabel(l10n, spec.key)),
                trailing: Text('${values[spec.key] ?? spec.defaultValue}',
                    style: Theme.of(context).textTheme.titleLarge),
                onTap: () async {
                  final v = await intDialog(
                    context,
                    title: settingLabel(l10n, spec.key),
                    initial: (values[spec.key] as num?)?.toInt() ??
                        spec.defaultValue as int,
                    min: spec.min,
                    max: spec.max,
                  );
                  if (v != null) onChanged(spec.key, v);
                },
              ),
          },
      ],
    );
  }
}
