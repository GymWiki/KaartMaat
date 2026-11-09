import 'package:flutter/material.dart';

/// Widest a list or form screen gets before the content stays centered. A
/// phone is narrower than this, so nothing changes there.
const double kContentMaxWidth = 720;

/// Width from which the layout counts as "tablet" (the usual 600 dp rule).
const double kTabletWidth = 600;

/// Keeps [child] at a comfortable width on wide screens (tablets, landscape)
/// and centered. The height is not restricted.
class ContentWidth extends StatelessWidget {
  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = kContentMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Extra side padding that keeps a full-width list at [kContentMaxWidth]:
/// nothing on a phone, a growing margin on wide screens.
EdgeInsets contentPadding(
  BuildContext context, [
  EdgeInsets base = EdgeInsets.zero,
]) {
  final extra = ((MediaQuery.sizeOf(context).width - kContentMaxWidth) / 2)
      .clamp(0.0, double.infinity);
  return base + EdgeInsets.symmetric(horizontal: extra);
}
