import 'dart:convert';

import 'package:flutter/services.dart';

import '../games/rules/rules_registry.dart';

/// One rulebook, read from `assets/rulebooks/<game>.json` and filled with the
/// settings of a game. Pure data: the screen only draws it.
///
/// File format (all texts Dutch, `{key}` is replaced by a setting value):
/// - `texts`: named fragments that depend on one setting:
///   `{ "name": { "by": "settingKey", "cases": { "true": "…", "default": "…" } } }`
///   and are used as `{name}` in any other text.
/// - `goal`, `needs`, `flow`, `tips`: lists of items (a string, or
///   `{ "text": "…", "if": "key=value" }`).
/// - `scoring`: `{ "intro": [items], "table": [{ "cols": [a, b], "if": … }],
///   "notes": [items] }`.
/// - `rules`: `[{ "title": "…", "text": "…", "if": … }]`.
/// `if` is `key=value`, `key` (a switched-on setting) or `!key`.
class Rulebook {
  const Rulebook({
    required this.title,
    required this.goal,
    required this.needs,
    required this.flow,
    required this.scoringIntro,
    required this.scoringTable,
    required this.scoringNotes,
    required this.rules,
    required this.tips,
  });

  final String title;
  final List<String> goal;
  final List<String> needs;
  final List<String> flow;
  final List<String> scoringIntro;
  final List<List<String>> scoringTable;
  final List<String> scoringNotes;
  final List<({String title, String text})> rules;
  final List<String> tips;

  static final _placeholder = RegExp(r'\{([\w.]+)\}');

  /// Settings of [type] with the game's own [overrides] on top of the defaults.
  static Map<String, Object?> valuesFor(
    String type,
    Map<String, Object?> overrides,
  ) => {...rulesFor(type).defaultSettings, ...overrides};

  static String path(String type) => 'assets/rulebooks/$type.json';

  static Future<Rulebook> load(
    String type,
    Map<String, Object?> settings, {
    AssetBundle? bundle,
  }) async {
    final raw = await (bundle ?? rootBundle).loadString(path(type));
    return parse(
      jsonDecode(raw) as Map<String, dynamic>,
      valuesFor(type, settings),
    );
  }

  static Rulebook parse(
    Map<String, dynamic> json,
    Map<String, Object?> values,
  ) {
    bool test(Object? cond) {
      if (cond is! String) return true;
      if (cond.startsWith('!')) return !_on(values[cond.substring(1)]);
      final eq = cond.indexOf('=');
      if (eq < 0) return _on(values[cond]);
      return '${values[cond.substring(0, eq)]}' == cond.substring(eq + 1);
    }

    // named fragments first, so other texts can use them
    final vars = <String, String>{
      for (final e in values.entries) e.key: '${e.value}',
    };
    final texts = (json['texts'] as Map?) ?? const {};
    for (final e in texts.entries) {
      final def = e.value as Map;
      final cases = (def['cases'] as Map).cast<String, Object?>();
      final value = '${values[def['by']]}';
      vars['${e.key}'] = '${cases[value] ?? cases['default'] ?? ''}';
    }
    String fill(String s) {
      // fragments may use settings, so fill twice
      for (var i = 0; i < 2; i++) {
        s = s.replaceAllMapped(_placeholder, (m) => vars[m[1]] ?? m[0]!);
      }
      return s;
    }

    List<String> items(Object? list) => [
      for (final i in (list as List?) ?? const [])
        if (i is String)
          fill(i)
        else if (test((i as Map)['if']))
          fill('${i['text']}'),
    ];

    final scoring = (json['scoring'] as Map?) ?? const {};
    return Rulebook(
      title: '${json['title']}',
      goal: items(json['goal']),
      needs: items(json['needs']),
      flow: items(json['flow']),
      scoringIntro: items(scoring['intro']),
      scoringTable: [
        for (final r in (scoring['table'] as List?) ?? const [])
          if (test((r as Map)['if']))
            [for (final c in r['cols'] as List) fill('$c')],
      ],
      scoringNotes: items(scoring['notes']),
      rules: [
        for (final r in (json['rules'] as List?) ?? const [])
          if (test((r as Map)['if']))
            (title: fill('${r['title']}'), text: fill('${r['text']}')),
      ],
      tips: items(json['tips']),
    );
  }

  static bool _on(Object? v) => v == true || v == 'true';

  /// Every text of the book, for checks.
  Iterable<String> get allTexts => [
    ...goal,
    ...needs,
    ...flow,
    ...scoringIntro,
    for (final r in scoringTable) ...r,
    ...scoringNotes,
    for (final r in rules) ...[r.title, r.text],
    ...tips,
  ];
}
