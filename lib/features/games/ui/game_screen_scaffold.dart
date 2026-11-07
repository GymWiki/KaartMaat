import 'package:flutter/material.dart';

/// One screen for a running game: the standings and rounds on top, an input
/// panel in the thumb zone at the bottom.
///
/// The panel never takes more than [maxPanelFraction] of the available height,
/// so the standings stay visible while entering. A panel that is taller than
/// that scrolls inside its frame instead of overflowing. The panel keeps clear
/// of the system gesture bar and shrinks with the screen when a keyboard
/// shows up.
class GameScreenScaffold extends StatefulWidget {
  const GameScreenScaffold({
    super.key,
    required this.top,
    this.panel,
    this.maxPanelFraction = 0.5,
    this.panelInset,
  });

  /// Standings and round table. Fills the space above the panel.
  final Widget top;

  /// The input panel. Null hides it (for example once the game is over).
  final Widget? panel;

  final double maxPanelFraction;

  /// Optional: receives the height the panel covers, for callers that show
  /// overlays (like the undo snackbar) from outside the scaffold.
  final ValueNotifier<double>? panelInset;

  /// Height the panel covers right now, so other overlays (like the undo
  /// snackbar) can float above it. 0 without a panel or outside a scaffold.
  static double panelInsetOf(BuildContext context, {bool listen = false}) {
    final scope = listen
        ? context.dependOnInheritedWidgetOfExactType<_PanelInset>()
        : context.getInheritedWidgetOfExactType<_PanelInset>();
    return scope?.notifier?.value ?? 0;
  }

  @override
  State<GameScreenScaffold> createState() => _GameScreenScaffoldState();
}

class _GameScreenScaffoldState extends State<GameScreenScaffold> {
  final _panelKey = GlobalKey();
  final _ownInset = ValueNotifier<double>(0);

  ValueNotifier<double> get _inset => widget.panelInset ?? _ownInset;

  @override
  void dispose() {
    _ownInset.dispose();
    super.dispose();
  }

  void _measure() {
    if (!mounted) return;
    final height = widget.panel == null
        ? 0.0
        : (_panelKey.currentContext?.size?.height ?? 0.0);
    if (_inset.value != height) _inset.value = height;
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final scheme = Theme.of(context).colorScheme;
    final animate = !MediaQuery.disableAnimationsOf(context);

    return _PanelInset(
      notifier: _inset,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The cap is for the content: the gesture bar comes on top of it.
          final maxPanel = constraints.maxHeight * widget.maxPanelFraction +
              MediaQuery.paddingOf(context).bottom;
          return Column(
            children: [
              Expanded(child: widget.top),
              if (widget.panel != null)
                AnimatedSize(
                  duration: animate
                      ? const Duration(milliseconds: 180)
                      : Duration.zero,
                  alignment: Alignment.bottomCenter,
                  child: Material(
                    key: _panelKey,
                    color: scheme.surfaceContainerHigh,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      side: BorderSide(color: scheme.outlineVariant),
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: maxPanel),
                      child: SafeArea(
                        top: false,
                        child: SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                            child: widget.panel,
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

class _PanelInset extends InheritedNotifier<ValueNotifier<double>> {
  const _PanelInset({
    required ValueNotifier<double> notifier,
    required super.child,
  }) : super(notifier: notifier);
}
