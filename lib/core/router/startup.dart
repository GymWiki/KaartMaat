import '../../features/games/data/game_repository.dart';
import '../../features/history/finished_game_screen.dart' show lastResultKey;
import '../../features/settings/data/settings_repository.dart';

/// Where the app should open after it was killed on a result screen: that
/// result screen, as long as its game still exists and is finished. Null for
/// a normal start. A stale marker is cleared.
Future<String?> resultLocationToRestore(
  SettingsRepository settings,
  GameRepository games,
) async {
  final raw = await settings.get(lastResultKey);
  if (raw == null) return null;
  final id = int.tryParse(raw);
  final state = id == null ? null : await games.load(id);
  if (state == null || !state.isFinished) {
    await settings.remove(lastResultKey);
    return null;
  }
  return '/finished/$id';
}
