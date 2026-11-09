import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/player_selector.dart';
import '../../../core/ui/seat_chips.dart';
import '../../../core/ui/quick_button_row.dart';
import '../../../core/ui/suits.dart';
import '../../../core/ui/touch.dart';
import '../rules/game_rules.dart';
import '../rules/klaverjas_rules.dart';

/// "hearts" -> [Suit.hearts] and back, for the suit stored in a Gronings hand.
Suit suitOf(String key) => switch (key) {
  'hearts' => Suit.hearts,
  'diamonds' => Suit.diamonds,
  'spades' => Suit.spades,
  _ => Suit.clubs,
};

String suitKey(Suit suit) => switch (suit) {
  Suit.hearts => 'hearts',
  Suit.diamonds => 'diamonds',
  Suit.spades => 'spades',
  Suit.clubs => 'clubs',
};

String suitName(AppLocalizations l10n, String key) => switch (key) {
  'hearts' => l10n.suitHearts,
  'diamonds' => l10n.suitDiamonds,
  'spades' => l10n.suitSpades,
  _ => l10n.suitClubs,
};

/// The unicode suit sign, for the compact round table.
String suitSign(String key) => switch (key) {
  'hearts' => '♥',
  'diamonds' => '♦',
  'spades' => '♠',
  _ => '♣',
};

/// Step 1 of a Gronings hand: who bids what. Pick a player, then tap an
/// opening bid, or (once somebody has bid) a raise of +10, +20 or +30. The
/// last bid is the highest, so the bidding is a list that only grows. Nothing
/// invalid can be tapped: the buttons that are not allowed are greyed out.
class GroningsBidStep extends StatelessWidget {
  const GroningsBidStep({
    super.key,
    required this.rules,
    required this.config,
    required this.number,
    required this.nameOf,
    required this.bids,
    required this.focus,
    required this.onFocus,
    required this.onBid,
    required this.onClear,
    required this.onPassAll,
    required this.onNext,
  });

  final KlaverjasRules rules;
  final GameConfig config;
  final int number;
  final String Function(String player) nameOf;

  /// The bidding so far, in order; the last entry is the highest bid.
  final List<({String player, int bid})> bids;

  /// The player whose bid is being entered.
  final String focus;
  final ValueChanged<String> onFocus;
  final ValueChanged<int> onBid;
  final VoidCallback onClear;

  /// Everybody passed: the player left of the dealer has to bid the minimum.
  final VoidCallback onPassAll;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final order = rules.bidOrder(config, number);
    final highest = bids.isEmpty ? null : bids.last;
    final starter = rules.bidStarter(config, number);

    // The latest bid of every player, and who holds the highest one.
    final latest = <String, int>{for (final b in bids) b.player: b.bid};

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PlayerSelector(
          chips: [
            for (final p in order)
              PlayerChipData(
                label: nameOf(p),
                marker: p == rules.dealer(config, number)
                    ? SeatMarker.dealer
                    : p == starter
                    ? SeatMarker.firstBidder
                    : null,
                value: latest[p]?.toString(),
                done: highest?.player == p,
              ),
          ],
          selectedIndex: order.indexOf(focus).clamp(0, order.length - 1),
          onSelected: (i) => onFocus(order[i]),
        ),
        const SizedBox(height: kTouchGap),
        if (highest == null)
          QuickButtonRow(
            buttonSize: 48,
            gap: 6,
            values: rules.openingBids(config),
            onSelected: onBid,
          )
        else
          Row(
            children: [
              for (final step in const [10, 20, 30]) ...[
                Expanded(
                  child: SizedBox(
                    height: kTouchTarget,
                    child: FilledButton.tonal(
                      // a player cannot raise their own bid
                      onPressed:
                          focus != highest.player &&
                              rules.isValidRaise(
                                config,
                                highest.bid,
                                highest.bid + step,
                              )
                          ? () => onBid(highest.bid + step)
                          : null,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n.groningsRaise(step),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                            Text(
                              '${highest.bid + step}',
                              style: const TextStyle(fontSize: 12, height: 1.1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (step != 30) const SizedBox(width: kTouchGap),
              ],
            ],
          ),
        const SizedBox(height: kTouchGap),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: kTouchTarget,
                child: OutlinedButton(
                  // no bid yet: "everybody passes"; else take the last bid back
                  onPressed: highest == null ? onPassAll : onClear,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      highest == null ? l10n.groningsPass : l10n.groningsClearBid,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: kTouchGap),
            Expanded(
              flex: 3,
              child: SizedBox(
                height: kTouchTarget,
                child: FilledButton(
                  onPressed: highest == null ? null : onNext,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(l10n.groningsToTrump),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 18,
          child: Text(
            highest == null
                ? l10n.groningsForced(nameOf(starter), rules.minBid(config))
                : l10n.groningsBidSummary(nameOf(highest.player), highest.bid),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

/// Step 2 of a Gronings hand: the trump suit, four big buttons. The suit the
/// bidder played last time is preselected; tapping a suit goes on at once.
class GroningsSuitStep extends StatelessWidget {
  const GroningsSuitStep({
    super.key,
    required this.suit,
    required this.onSuit,
    required this.onBack,
    required this.onNext,
  });

  final String? suit;
  final ValueChanged<String> onSuit;
  final VoidCallback onBack;

  /// Go on with the suit that is selected (a preselected one needs no new tap
  /// on the suit itself).
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (final key in KlaverjasRules.suits) ...[
              Expanded(
                child: Semantics(
                  button: true,
                  selected: suit == key,
                  label: suitName(l10n, key),
                  excludeSemantics: true,
                  child: SizedBox(
                    height: 88,
                    child: Material(
                      color: suit == key
                          ? scheme.primary
                          : scheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: suit == key
                              ? scheme.primary
                              : scheme.outlineVariant,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => onSuit(key),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SuitPip(
                              suitOf(key),
                              size: 34,
                              // black suits on the gold of a selected button
                              color:
                                  suit == key &&
                                      (key == 'spades' || key == 'clubs')
                                  ? AppTheme.ink
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                suitName(l10n, key),
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                  color: suit == key
                                      ? AppTheme.ink
                                      : scheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (key != KlaverjasRules.suits.last)
                const SizedBox(width: kTouchGap),
            ],
          ],
        ),
        const SizedBox(height: kTouchGap),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: SizedBox(
                height: kTouchTarget,
                child: OutlinedButton(
                  onPressed: onBack,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(l10n.groningsBidTitle),
                  ),
                ),
              ),
            ),
            const SizedBox(width: kTouchGap),
            Expanded(
              flex: 3,
              child: SizedBox(
                height: kTouchTarget,
                child: FilledButton(
                  onPressed: suit == null ? null : onNext,
                  child: Text(l10n.next),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
