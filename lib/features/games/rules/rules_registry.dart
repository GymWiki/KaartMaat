import 'custom_rules.dart';
import 'game_rules.dart';

const Map<String, GameRules> allRules = {
  CustomRules.typeId: CustomRules(),
};

GameRules rulesFor(String type) =>
    allRules[type] ?? (throw ArgumentError('Unknown game type: $type'));
