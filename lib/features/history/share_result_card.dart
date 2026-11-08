import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/l10n/l10n.dart';
import '../../core/ui/avatars.dart';
import '../games/data/game_state.dart';
import '../games/games_registry.dart';
import '../games/rules/klaverjas_rules.dart';
import '../settings/ui/settings_editor.dart' show optionLabel;
import 'result_image.dart' show badgesFor;

/// One line of the final ranking, ready to draw.
class ResultRow {
  const ResultRow({
    required this.rank,
    required this.title,
    required this.members,
    required this.avatars,
    required this.total,
    required this.crown,
    required this.donkey,
    required this.isTeam,
  });

  final int rank;

  /// Player name, or "Wij" / "Zij" for a team.
  final String title;

  /// Player names of a team (empty for a single player).
  final List<String> members;
  final List<int> avatars;
  final int total;
  final bool crown;
  final bool donkey;
  final bool isTeam;
}

/// "Klaverjassen, Amsterdams" for games where the variant matters.
String resultTitle(AppLocalizations l10n, GameState state) {
  final name = definitionFor(state.type).name(l10n);
  if (state.type == KlaverjasRules.typeId) {
    final v = state.settings[KlaverjasRules.variantKey];
    if (v is String) return '$name, ${optionLabel(l10n, v)}';
  }
  return name;
}

/// The ranking of [view] as plain data. Ties share a rank; the order already
/// respects lowest-wins and highest-wins.
List<ResultRow> resultRows(AppLocalizations l10n, GameView view) {
  final badges = badgesFor(view);
  final byKey = {for (final p in view.state.players) p.key: p};
  final isTeamGame =
      view.config.participants.length != view.config.players.length ||
      view.config.participants.any((p) => !byKey.containsKey(p));
  return [
    for (final s in view.standings)
      () {
        final members = view.rules.membersOf(view.config, s.participant);
        final names = [for (final m in members) byKey[m]?.name ?? '?'];
        final team = isTeamGame && members.length > 1;
        return ResultRow(
          rank: s.rank,
          title: team
              ? (s.participant == KlaverjasRules.wij
                    ? l10n.teamWij
                    : l10n.teamZij)
              : view.nameOf(s.participant),
          members: team ? names : const [],
          avatars: [for (final m in members) byKey[m]?.avatar ?? 0],
          total: s.total,
          crown: badges.crown.contains(s.participant),
          donkey: badges.donkey.contains(s.participant),
          isTeam: team,
        );
      }(),
  ];
}

/// Text that goes with the shared picture.
String shareCaption(AppLocalizations l10n, GameView view) {
  final game = definitionFor(view.state.type).name(l10n);
  final rows = resultRows(l10n, view);
  if (rows.isEmpty) return game;
  final winners = rows.where((r) => r.rank == 1).toList();
  final names = winners
      .map((r) => r.isTeam ? r.members.join(' & ') : r.title)
      .join(', ');
  return winners.length == 1
      ? l10n.shareCaption(game, names, winners.first.total)
      : l10n.shareCaptionTie(game, names, winners.first.total);
}

const _felt1 = Color(0xFF1F6B45);
const _felt2 = Color(0xFF0F3D26);
const _muted = Color(0xFFB9D8C6);
const _gold = Color(0xFFF2C94C);

/// The picture that is shared, and the preview on the result screen: the
/// same widget. Fixed 4:5 (360 x 450 dp renders to 1080 x 1350 px at 3x),
/// fixed colors and fixed sizes: it ignores the app theme and the system
/// font scale, so it looks the same on every phone.
class ShareResultCard extends StatelessWidget {
  const ShareResultCard({super.key, required this.view, this.crownProgress});

  static const width = 360.0;
  static const height = 450.0;

  final GameView view;

  /// 0..1: the crown settles on the winner. Null = at rest (always for the
  /// exported picture).
  final Animation<double>? crownProgress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = resultRows(l10n, view);
    final winners = rows.where((r) => r.rank == 1).toList();
    final started = view.state.rounds.isNotEmpty;
    final date = DateFormat(
      'd MMMM yyyy',
      'nl',
    ).format(view.state.finishedAt ?? view.state.createdAt);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_felt1, _felt2],
            ),
          ),
          child: DefaultTextStyle(
            style: const TextStyle(
              fontFamily: 'RobotoCondensed',
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 14,
              decoration: TextDecoration.none,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    resultTitle(l10n, view.state),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 24),
                  ),
                  Text(
                    date,
                    style: const TextStyle(fontSize: 13, color: _muted),
                  ),
                  const SizedBox(height: 10),
                  if (started && winners.isNotEmpty)
                    _Winner(winners: winners, progress: crownProgress),
                  const SizedBox(height: 8),
                  Expanded(child: _Ranking(rows: started ? rows : const [])),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      l10n.roundsPlayed(view.state.rounds.length),
                      style: const TextStyle(fontSize: 12, color: _muted),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Center(
                    child: Text(
                      l10n.shareWatermark,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xCCFFFFFF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Winner extends StatelessWidget {
  const _Winner({required this.winners, required this.progress});
  final List<ResultRow> winners;
  final Animation<double>? progress;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tie = winners.length > 1;
    final names = winners
        .map((r) => r.isTeam ? r.members.join(' & ') : r.title)
        .join(tie ? '  ·  ' : '');
    final crown = CrownBadge(size: tie ? 26 : 30);
    return SizedBox(
      height: tie ? 126 : 110,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _gold.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              progress == null
                  ? crown
                  : AnimatedBuilder(
                      animation: progress!,
                      builder: (_, child) {
                        final t = Curves.easeOutBack.transform(progress!.value);
                        return Opacity(
                          opacity: progress!.value.clamp(0.0, 1.0),
                          child: Transform.translate(
                            offset: Offset(0, -16 * (1 - t)),
                            child: child,
                          ),
                        );
                      },
                      child: crown,
                    ),
              if (tie)
                Text(
                  l10n.sharedWin,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.1,
                    color: _gold,
                  ),
                ),
              Text(
                names,
                maxLines: tie ? 2 : 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: tie ? 16 : 26, height: 1.15),
              ),
              Text(
                '${winners.first.total}',
                style: TextStyle(
                  fontSize: tie ? 30 : 36,
                  height: 1.0,
                  color: _gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Ranking extends StatelessWidget {
  const _Ranking({required this.rows});
  final List<ResultRow> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 4.0;
        final team = rows.any((r) => r.isTeam);
        final raw = (c.maxHeight - gap * (rows.length - 1)) / rows.length;
        final h = raw.clamp(20.0, team ? 52.0 : 44.0);
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: gap),
              _RankRow(row: rows[i], height: h),
            ],
          ],
        );
      },
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.row, required this.height});
  final ResultRow row;
  final double height;

  @override
  Widget build(BuildContext context) {
    final avatar = (height - 6).clamp(14.0, 36.0);
    final nameSize = (height * 0.45).clamp(11.0, 18.0);
    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(height / 2.6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  '${row.rank}',
                  style: TextStyle(fontSize: nameSize + 2),
                ),
              ),
              if (row.avatars.length > 1)
                SizedBox(
                  width: avatar * 1.5,
                  height: avatar,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        child: PlayerAvatar(
                          index: row.avatars[0],
                          size: avatar,
                        ),
                      ),
                      Positioned(
                        left: avatar * 0.5,
                        child: PlayerAvatar(
                          index: row.avatars[1],
                          size: avatar,
                        ),
                      ),
                    ],
                  ),
                )
              else
                PlayerAvatar(
                  index: row.avatars.isEmpty ? 0 : row.avatars.first,
                  size: avatar,
                ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: nameSize),
                    ),
                    if (row.isTeam)
                      Text(
                        row.members.join(' & '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, color: _muted),
                      ),
                  ],
                ),
              ),
              if (row.crown) CrownBadge(size: (height * 0.6).clamp(14.0, 24.0)),
              if (row.donkey)
                DonkeyBadge(size: (height * 0.6).clamp(14.0, 24.0)),
              const SizedBox(width: 8),
              Text('${row.total}', style: TextStyle(fontSize: nameSize + 4)),
            ],
          ),
        ),
      ),
    );
  }
}
