import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../data/game_state.dart';

/// Rounds as rows, players or teams as columns. The header with names and
/// running totals stays in place; the rounds scroll underneath and the list
/// follows the current round.
///
/// - [currentRound] is highlighted (a dashed placeholder row is added when it
///   has not been stored yet).
/// - [editingRound] is the round loaded in the input panel.
/// - [onTapRound] makes rows tappable (to edit that round).
/// - [cellDetail] adds a small second line to a cell (e.g. "bod 2 / 3 gehaald").
/// - [cellHighlight] marks a cell with a check and a tint (e.g. exact bid).
///   The check keeps the meaning when color is hard to see.
class RoundTable extends StatefulWidget {
  const RoundTable({
    super.key,
    required this.view,
    this.currentRound,
    this.editingRound,
    this.onTapRound,
    this.cellDetail,
    this.cellHighlight,
  });

  final GameView view;
  final int? currentRound;
  final int? editingRound;
  final void Function(int roundNumber)? onTapRound;
  final String? Function(int roundIndex, String participant)? cellDetail;
  final bool Function(int roundIndex, String participant)? cellHighlight;

  @override
  State<RoundTable> createState() => _RoundTableState();
}

class _RoundTableState extends State<RoundTable> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RoundTable old) {
    super.didUpdateWidget(old);
    if (old.view.state.rounds.length != widget.view.state.rounds.length ||
        old.currentRound != widget.currentRound) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_controller.hasClients) return;
        final target = _controller.position.maxScrollExtent;
        if (MediaQuery.disableAnimationsOf(context)) {
          _controller.jumpTo(target);
        } else {
          _controller.animateTo(
            target,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final view = widget.view;
    final ids = view.config.participants;
    final totals = {for (final s in view.standings) s.participant: s};
    final rounds = view.state.rounds;
    final ghost =
        widget.currentRound != null &&
        !rounds.any((r) => r.number == widget.currentRound);

    Widget numberCell(
      String text, {
      bool bold = false,
      Color? color,
      double size = 18,
    }) => Expanded(
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            maxLines: 1,
            style: TextStyle(
              fontFamily: bold ? AppTheme.numeralFont : null,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              fontSize: size,
              color: color ?? scheme.onSurface,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );

    Widget rowFrame({
      required Widget child,
      Color? color,
      BoxBorder? border,
      VoidCallback? onTap,
      String? semantics,
    }) => Semantics(
      button: onTap != null,
      label: semantics,
      excludeSemantics: semantics != null,
      child: Material(
        color: color ?? Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            decoration: BoxDecoration(border: border),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: child,
          ),
        ),
      ),
    );

    Widget roundRow(int? index, int number) {
      final stored = index != null;
      final complete = stored ? view.roundComplete[index] : false;
      final editing = widget.editingRound == number;
      final current = widget.currentRound == number;
      final scores = stored ? view.roundScores[index] : null;

      return rowFrame(
        color: editing
            ? scheme.primaryContainer
            : current
            ? scheme.primary.withValues(alpha: 0.14)
            : null,
        border: Border(
          left: BorderSide(
            color: current || editing ? scheme.primary : Colors.transparent,
            width: 4,
          ),
          bottom: BorderSide(color: scheme.outlineVariant),
        ),
        onTap: widget.onTapRound == null || !stored && !current
            ? null
            : () => widget.onTapRound!(number),
        semantics: [
          l10n.roundTitle(number),
          if (editing) l10n.editing,
          if (stored && complete)
            for (final p in ids) '${view.nameOf(p)} ${scores![p]}',
        ].join(', '),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: Text(
                '$number',
                style: TextStyle(
                  fontWeight: current || editing
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            for (final p in ids)
              () {
                final highlight =
                    stored &&
                    complete &&
                    (widget.cellHighlight?.call(index, p) ?? false);
                final detail = stored
                    ? widget.cellDetail?.call(index, p)
                    : null;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 2,
                      vertical: 4,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: highlight
                          ? scheme.secondary.withValues(alpha: 0.18)
                          : null,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (highlight)
                              Padding(
                                padding: const EdgeInsets.only(right: 3),
                                child: Icon(
                                  Icons.check,
                                  size: 14,
                                  color: scheme.secondary,
                                ),
                              ),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  stored && complete ? '${scores![p]}' : '–',
                                  style: TextStyle(
                                    fontFamily: AppTheme.numeralFont,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                    color: stored && complete && scores![p]! < 0
                                        ? scheme.error
                                        : scheme.onSurface,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (detail != null)
                          Text(
                            detail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }(),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Pinned header: names, then the running totals.
        rowFrame(
          color: scheme.surfaceContainer,
          border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          child: Row(
            children: [
              const SizedBox(width: 40),
              for (final p in ids) numberCell(view.nameOf(p), size: 13),
            ],
          ),
        ),
        rowFrame(
          color: scheme.surfaceContainer,
          border: Border(bottom: BorderSide(color: scheme.outline)),
          semantics: [
            l10n.total,
            for (final p in ids) '${view.nameOf(p)} ${totals[p]!.total}',
          ].join(', '),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  l10n.total,
                  style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              for (final p in ids)
                numberCell(
                  '${totals[p]!.total}',
                  bold: true,
                  size: 28,
                  color:
                      view.roundComplete.any((done) => done) &&
                          totals[p]!.rank == 1
                      ? scheme.tertiary
                      : scheme.onSurface,
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            controller: _controller,
            padding: const EdgeInsets.only(bottom: 8),
            children: [
              for (var i = 0; i < rounds.length; i++)
                roundRow(i, rounds[i].number),
              if (ghost) roundRow(null, widget.currentRound!),
            ],
          ),
        ),
      ],
    );
  }
}
