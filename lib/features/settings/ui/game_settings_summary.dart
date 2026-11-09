import '../../../core/l10n/l10n.dart';
import '../../games/rules/boerenbridge_rules.dart';
import '../../games/rules/canasta_rules.dart';
import '../../games/rules/custom_rules.dart';
import '../../games/rules/duizenden_rules.dart';
import '../../games/rules/hearts_rules.dart';
import '../../games/rules/jokeren_rules.dart';
import '../../games/rules/klaverjas_rules.dart';
import '../../games/rules/rikken_rules.dart';
import '../../games/rules/toepen_rules.dart';
import 'settings_editor.dart';

/// One short line with the most important current values of a game, shown
/// under the game name in the settings accordion. [values] are the stored
/// options on top of the defaults.
String gameSettingsSummary(
  AppLocalizations l10n,
  String type,
  Map<String, Object?> values,
) {
  int n(String key) => (values[key] as num?)?.toInt() ?? 0;
  String win(bool lowest) => lowest ? l10n.sumLowestWins : l10n.sumHighestWins;

  switch (type) {
    case BoerenbridgeRules.typeId:
      return l10n.sumBoerenbridge(
        n(BoerenbridgeRules.exactBaseKey),
        n(BoerenbridgeRules.exactPerTrickKey),
        n(BoerenbridgeRules.wrongPerTrickKey),
      );
    case KlaverjasRules.typeId:
      final variant = optionLabel(l10n, '${values[KlaverjasRules.variantKey]}');
      return values[KlaverjasRules.endModeKey] == KlaverjasRules.endModeTarget
          ? l10n.sumKlaverjasTarget(variant, n(KlaverjasRules.targetScoreKey))
          : l10n.sumKlaverjasHands(variant, n(KlaverjasRules.roundsKey));
    case RikkenRules.typeId:
      return l10n.sumRikken(
        n(RikkenRules.perTrickKey),
        n(RikkenRules.slamBonusKey),
      );
    case HeartsRules.typeId:
      final rounds = n(HeartsRules.roundsKey);
      return rounds > 0
          ? l10n.sumHeartsRounds(n(HeartsRules.totalPointsKey), rounds)
          : l10n.sumHearts(
              n(HeartsRules.totalPointsKey),
              n(HeartsRules.targetScoreKey),
            );
    case ToepenRules.typeId:
      return l10n.sumToepen(n(ToepenRules.limitKey));
    case JokerenRules.typeId:
      final w = win(values[JokerenRules.lowestWinsKey] == true);
      final rounds = n(JokerenRules.roundsKey);
      final target = n(JokerenRules.targetScoreKey);
      return rounds > 0
          ? l10n.sumRoundsWin(rounds, w)
          : target > 0
              ? l10n.sumTargetWin(target, w)
              : w;
    case CanastaRules.typeId:
      return l10n.sumCanasta(
        n(CanastaRules.targetScoreKey),
        n(CanastaRules.naturalCanastaKey),
        n(CanastaRules.mixedCanastaKey),
      );
    case DuizendenRules.typeId:
      return l10n.sumTarget(n(DuizendenRules.targetScoreKey));
    case CustomRules.typeId:
      final base = values[CustomRules.inputModeKey] == CustomRules.inputModeEnter
          ? l10n.sumCustomEnter
          : l10n.sumCustomAdd(n(CustomRules.stepKey));
      final target = n(CustomRules.targetScoreKey);
      return target > 0 ? l10n.sumCustomTarget(base, target) : base;
    default:
      return '';
  }
}
