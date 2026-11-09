# Kaartmaat

Flutter scorekeeper for physical card and dice games. Android first, Dutch UI,
fully offline, no accounts, ads or tracking. Used at a table, often in dim
light and one-handed: fast input and never losing state come first.

## Architecture
- Feature-first: `lib/features/{games,players,history,stats,settings}`,
  shared code in `lib/core/{db,theme,router,l10n,ui}`.
- State: Riverpod. Storage: Drift (SQLite). Navigation: go_router.
- Game rules are pure Dart in `lib/features/games/rules/` (no Flutter or UI
  imports). One `GameRules` class per game. Scoring values and rule variants
  are settings (`SettingSpec`), never constants.
- Totals are never stored; they are derived from `Rounds` via `GameView`.
  A round may be stored incomplete (`isRoundComplete`), so games resume
  exactly where they were.
- `lib/features/games/games_registry.dart` is the single list of games
  (name, icon, rules, entry UI). The home screen is generated from it.
  Add a game: rules class + `rules_registry.dart` + a `GameDefinition`.
- UI strings live in `lib/core/l10n/app_nl.arb`. No hardcoded UI strings.

## Working agreements
- One branch per phase, small commits, `flutter analyze` and `flutter test`
  green before each commit.
- If a rule is ambiguous: write a Dutch rules summary and open questions, wait
  for confirmation, make variants a setting.
- No dependencies beyond what a phase needs; name each one and why.
- Never commit secrets, keystores or certificates.
- Pro: one non-consumable purchase (`kaartmaat_pro`) unlocks Statistieken,
  Historie (finished games) and player groups; all games stay free. Every Pro
  check goes through `EntitlementService` (`lib/features/pro/`, watch
  `entitlementProvider`), never the store directly; UI parts use `ProGate`.
  Game data is always stored, only showing it is gated. Pro is stored locally
  and is never taken away because the store could not be reached.
- `in_app_purchase` is the one dependency added for Pro (store purchases).

## Commands
- Codegen (Drift): `dart run build_runner build --force-jit --delete-conflicting-outputs`
  (`--force-jit` is needed because of a build-hook conflict in the dependency graph).
- l10n: `flutter gen-l10n` (also runs on build).
- Drift is pinned to 2.31 / drift_flutter 0.2.7 so drift_dev resolves.
