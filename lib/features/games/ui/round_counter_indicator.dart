import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';

/// "A round was added" signal. Change [tick] to play the confirmation; the
/// [message] is announced to screen readers ("Ronde 4 opgeslagen").
typedef RoundSignal = ({int tick, String message});

/// Round label of the game screen (round, dealer, cards) with an undo button.
///
/// When [roundAdded] changes, the label briefly turns green and a small "+1"
/// floats up and fades out, without touching the layout or blocking taps. A
/// single controller drives everything, so quick successive rounds restart the
/// animation instead of stacking particles. With the system "reduce motion"
/// setting only the colour change remains. Only this widget rebuilds while it
/// plays. [onUndo] null disables the undo button.
class RoundCounterIndicator extends StatefulWidget {
  const RoundCounterIndicator({
    super.key,
    required this.label,
    required this.roundAdded,
    this.onUndo,
  });

  final String label;
  final ValueListenable<RoundSignal> roundAdded;
  final VoidCallback? onUndo;

  @override
  State<RoundCounterIndicator> createState() => _RoundCounterIndicatorState();
}

class _RoundCounterIndicatorState extends State<RoundCounterIndicator>
    with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    value: 1, // idle
  );
  int _lastTick = 0;

  @override
  void initState() {
    super.initState();
    _lastTick = widget.roundAdded.value.tick;
    widget.roundAdded.addListener(_onSignal);
  }

  @override
  void didUpdateWidget(RoundCounterIndicator old) {
    super.didUpdateWidget(old);
    if (old.roundAdded != widget.roundAdded) {
      old.roundAdded.removeListener(_onSignal);
      _lastTick = widget.roundAdded.value.tick;
      widget.roundAdded.addListener(_onSignal);
    }
  }

  void _onSignal() {
    final tick = widget.roundAdded.value.tick;
    if (tick == _lastTick) return;
    _lastTick = tick;
    _anim.forward(from: 0);
  }

  @override
  void dispose() {
    widget.roundAdded.removeListener(_onSignal);
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    // Enough contrast on the surface in light, dark and OLED.
    final green = Theme.of(context).brightness == Brightness.dark
        ? Colors.greenAccent.shade200
        : Colors.green.shade800;
    final style = Theme.of(
      context,
    ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800);

    return Container(
      width: double.infinity,
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(16, 0, 4, 0),
      constraints: const BoxConstraints(minHeight: 56),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final t = _anim.value;
          final playing = t < 1;
          final colorT = reduceMotion
              ? (t < 0.5 ? 0.0 : 1.0) // short colour change, no easing
              : Curves.easeOut.transform(t);
          final color = Color.lerp(green, scheme.onSurface, colorT);
          final signal = widget.roundAdded.value;
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.centerLeft,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      liveRegion: true,
                      excludeSemantics: true,
                      label: playing && signal.tick > 0
                          ? '${signal.message}. ${widget.label}'
                          : widget.label,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          style: style?.copyWith(color: color),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: context.l10n.undoAction,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    color: scheme.onSurfaceVariant,
                    onPressed: widget.onUndo,
                    icon: const Icon(Icons.undo),
                  ),
                ],
              ),
              if (playing && !reduceMotion)
                Positioned(
                  left: 16,
                  top: 4,
                  child: ExcludeSemantics(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: (1 - Curves.easeIn.transform(t)).clamp(
                          0.0,
                          1.0,
                        ),
                        child: Transform.translate(
                          offset: Offset(0, -28 * Curves.easeOut.transform(t)),
                          child: Text(
                            '+1',
                            style: TextStyle(
                              color: green,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
