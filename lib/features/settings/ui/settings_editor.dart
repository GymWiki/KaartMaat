import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/ui/dialogs.dart';
import '../../games/rules/boerenbridge_rules.dart';
import '../../games/rules/canasta_rules.dart';
import '../../games/rules/jokeren_rules.dart';
import '../../games/rules/custom_rules.dart';
import '../../games/rules/game_rules.dart';
import '../../games/rules/hearts_rules.dart';
import '../../games/rules/klaverjas_rules.dart';
import '../../games/rules/rikken_rules.dart';
import '../../games/rules/toepen_rules.dart';
import '../../games/ui/rikken_labels.dart';

String settingLabel(AppLocalizations l10n, String key) {
  if (key.startsWith(RikkenRules.basePrefix)) {
    return l10n.rikBaseLabel(rikContractName(
        l10n, key.substring(RikkenRules.basePrefix.length)));
  }
  return _settingLabel(l10n, key);
}

String _settingLabel(AppLocalizations l10n, String key) => switch (key) {
      CustomRules.targetScoreKey => l10n.settingTargetScore,
      CustomRules.lowestWinsKey => l10n.settingLowestWins,
      CustomRules.stepKey => l10n.settingStep,
      BoerenbridgeRules.dealerRestrictionKey => l10n.settingDealerRestriction,
      BoerenbridgeRules.exactBaseKey => l10n.settingExactBase,
      BoerenbridgeRules.exactPerTrickKey => l10n.settingExactPerTrick,
      BoerenbridgeRules.wrongPerTrickKey => l10n.settingWrongPerTrick,
      BoerenbridgeRules.maxCardsKey => l10n.settingMaxCards,
      KlaverjasRules.variantKey => l10n.settingVariant,
      CustomRules.inputModeKey => l10n.settingInputMode,
      KlaverjasRules.endModeKey => l10n.settingEndMode,
      KlaverjasRules.minBidKey => l10n.settingMinBid,
      KlaverjasRules.maxBidKey => l10n.settingMaxBid,
      CanastaRules.targetInclusiveKey => l10n.settingTargetInclusive,
      KlaverjasRules.tieIsNatKey => l10n.settingTieIsNat,
      KlaverjasRules.pitBonusKey => l10n.settingPitBonus,
      KlaverjasRules.roemThreeKey => l10n.settingRoemThree,
      KlaverjasRules.roemFourKey => l10n.settingRoemFour,
      KlaverjasRules.roemStukKey => l10n.settingRoemStuk,
      KlaverjasRules.roemFourEqualKey => l10n.settingRoemFourEqual,
      KlaverjasRules.roemFourJacksKey => l10n.settingRoemFourJacks,
      KlaverjasRules.roundsKey => l10n.settingRounds,
      HeartsRules.totalPointsKey => l10n.settingTotalPoints,
      HeartsRules.queenPointsKey => l10n.settingQueenPoints,
      HeartsRules.moonEnabledKey => l10n.settingMoonEnabled,
      HeartsRules.moonModeKey => l10n.settingMoonMode,
      ToepenRules.limitKey => l10n.settingLimit,
      ToepenRules.povertyKey => l10n.settingPoverty,
      ToepenRules.playOnKey => l10n.settingPlayOn,
      CanastaRules.naturalCanastaKey => l10n.settingNaturalCanasta,
      CanastaRules.mixedCanastaKey => l10n.settingMixedCanasta,
      CanastaRules.goOutKey => l10n.settingGoOut,
      CanastaRules.goOutConcealedKey => l10n.settingGoOutConcealed,
      CanastaRules.redThreeKey => l10n.settingRedThree,
      CanastaRules.allRedThreesKey => l10n.settingAllRedThrees,
      JokerenRules.quickJokerKey => l10n.settingQuickJoker,
      JokerenRules.quickAceKey => l10n.settingQuickAce,
      JokerenRules.quickFaceKey => l10n.settingQuickFace,
      RikkenRules.perTrickKey => l10n.settingPerTrick,
      RikkenRules.slamBonusKey => l10n.settingSlamBonus,
      RikkenRules.maatPaysKey => l10n.settingMaatPays,
      _ => key,
    };

String optionLabel(AppLocalizations l10n, String option) => switch (option) {
      KlaverjasRules.amsterdams => l10n.variantAmsterdams,
      KlaverjasRules.rotterdams => l10n.variantRotterdams,
      KlaverjasRules.gronings => l10n.variantGronings,
      CustomRules.inputModeAdd => l10n.inputModeAdd,
      CustomRules.inputModeEnter => l10n.inputModeEnter,
      KlaverjasRules.endModeHands => l10n.endModeHands,
      KlaverjasRules.endModeTarget => l10n.endModeTarget,
      HeartsRules.moonOthers => l10n.moonOthers,
      HeartsRules.moonShooter => l10n.moonShooter,
      _ => option,
    };

/// Small explanation under a switch, or null.
String? settingHint(AppLocalizations l10n, String key) =>
    key == BoerenbridgeRules.dealerRestrictionKey
        ? l10n.settingDealerRestrictionHint
        : null;

/// One line under a choice that explains the selected option.
String? optionHint(AppLocalizations l10n, String key, Object? option) =>
    key == CustomRules.inputModeKey
    ? switch (option) {
        CustomRules.inputModeAdd => l10n.inputModeHintAdd,
        CustomRules.inputModeEnter => l10n.inputModeHintEnter,
        _ => null,
      }
    : key == KlaverjasRules.variantKey
        ? switch (option) {
            KlaverjasRules.amsterdams => l10n.variantHintAmsterdams,
            KlaverjasRules.rotterdams => l10n.variantHintRotterdams,
            KlaverjasRules.gronings => l10n.variantHintGronings,
            _ => null,
          }
        : null;

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
        for (final spec in rules.settingSpecs.where(
          (s) =>
              s.visibleIf == null ||
              (values[s.visibleIf!.$1] ??
                      rules.defaultSettings[s.visibleIf!.$1]) ==
                  s.visibleIf!.$2,
        ))
          switch (spec.kind) {
            SettingKind.boolean => SwitchListTile(
                title: Text(settingLabel(l10n, spec.key)),
                subtitle: settingHint(l10n, spec.key) == null
                    ? null
                    : Text(
                        settingHint(l10n, spec.key)!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                value: values[spec.key] == true,
                onChanged: (v) => onChanged(spec.key, v),
              ),
            SettingKind.choice when spec.segmented => ListTile(
                title: Text(settingLabel(l10n, spec.key)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<String>(
                          showSelectedIcon: false,
                          segments: [
                            for (final option in spec.options)
                              ButtonSegment(
                                value: option,
                                label: Text(optionLabel(l10n, option)),
                              ),
                          ],
                          selected: {
                            (values[spec.key] ?? spec.defaultValue) as String,
                          },
                          onSelectionChanged: (v) =>
                              onChanged(spec.key, v.first),
                        ),
                      ),
                      if (optionHint(
                            l10n,
                            spec.key,
                            values[spec.key] ?? spec.defaultValue,
                          )
                          case final hint?)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            hint,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            SettingKind.choice => ListTile(
                title: Text(settingLabel(l10n, spec.key)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final option in spec.options)
                            ChoiceChip(
                              label: Text(optionLabel(l10n, option)),
                              selected:
                                  (values[spec.key] ?? spec.defaultValue) ==
                                  option,
                              onSelected: (_) => onChanged(spec.key, option),
                            ),
                        ],
                      ),
                      if (optionHint(
                            l10n,
                            spec.key,
                            values[spec.key] ?? spec.defaultValue,
                          )
                          case final hint?)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            hint,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
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
