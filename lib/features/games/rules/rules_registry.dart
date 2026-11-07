import 'boerenbridge_rules.dart';
import 'custom_rules.dart';
import 'game_rules.dart';
import 'klaverjas_rules.dart';

const Map<String, GameRules> allRules = {
  CustomRules.typeId: CustomRules(),
  BoerenbridgeRules.typeId: BoerenbridgeRules(),
  KlaverjasRules.typeId: KlaverjasRules(),
};

GameRules rulesFor(String type) =>
    allRules[type] ?? (throw ArgumentError('Unknown game type: $type'));
