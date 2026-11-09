import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import 'entitlement_service.dart';
import 'purchase_controller.dart';

/// Shows [child] for Pro users and the Pro wall (with a faded [preview]) for
/// everybody else. Used by Statistieken, Historie and, later, the groups. The
/// wall only appears when someone opens a Pro part, never at startup.
class ProGate extends ConsumerWidget {
  const ProGate({super.key, required this.child, required this.preview});

  final Widget child;

  /// What Pro would look like: the user's own data, or sample content.
  final Widget preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(entitlementProvider);
    // "Bedankt!" once, right after a purchase went through.
    ref.listen(purchaseControllerProvider.select((s) => s.notice), (_, notice) {
      if (notice == PurchaseNotice.thanks) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(context.l10n.proThanks)));
        ref.read(purchaseControllerProvider.notifier).clearNotice();
      }
    });
    return isPro ? child : ProWall(preview: preview);
  }
}

/// The wall itself: a lightly blurred preview, what Pro contains, the price
/// from the store, one big button and "Aankopen herstellen". Friendly and
/// plain: no countdowns, no pressure.
class ProWall extends ConsumerWidget {
  const ProWall({super.key, required this.preview});
  final Widget preview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final state = ref.watch(purchaseControllerProvider);
    final controller = ref.read(purchaseControllerProvider.notifier);
    final busy = state.phase != PurchasePhase.idle;

    Widget feature(String label) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 20, color: scheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: text.bodyLarge)),
        ],
      ),
    );

    final notice = switch (state.notice) {
      PurchaseNotice.pending => (l10n.proPending, false),
      PurchaseNotice.failed => (l10n.proFailed, true),
      PurchaseNotice.restoreNone => (l10n.proRestoreNone, false),
      _ => null,
    };

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: 220,
            child: ExcludeSemantics(
              child: IgnorePointer(
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.transparent],
                    stops: [0.45, 1],
                  ).createShader(rect),
                  child: ImageFiltered(
                    imageFilter: ui.ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                    // the preview gets a normal screen height and is cut off
                    // after the first 220 dp
                    child: ClipRect(
                      child: OverflowBox(
                        alignment: Alignment.topCenter,
                        minHeight: 600,
                        maxHeight: 600,
                        child: Opacity(opacity: 0.7, child: preview),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.proTitle, style: text.headlineMedium),
                const SizedBox(height: 8),
                Text(l10n.proIntro, style: text.bodyMedium),
                const SizedBox(height: 8),
                feature(l10n.proFeatureStats),
                feature(l10n.proFeatureHistory),
                feature(l10n.proFeatureGroups),
                const SizedBox(height: 16),
                if (state.product != null) ...[
                  Text(
                    state.product!.price,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(l10n.proOnce, style: text.bodyMedium),
                ] else if (state.loadingProduct)
                  Text(l10n.proLoadingPrice, style: text.bodyMedium)
                else ...[
                  Text(
                    l10n.proProductError,
                    style: text.bodyMedium?.copyWith(color: scheme.error),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: controller.loadProduct,
                    child: Text(l10n.proRetry),
                  ),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: FilledButton(
                    onPressed: state.product == null || busy
                        ? null
                        : controller.buy,
                    child: state.phase == PurchasePhase.purchasing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Text(l10n.proUnlock),
                  ),
                ),
                if (notice != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Semantics(
                      liveRegion: true,
                      child: Text(
                        notice.$1,
                        style: text.bodyMedium?.copyWith(
                          color: notice.$2 ? scheme.error : null,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed:
                      state.phase == PurchasePhase.purchasing ||
                          state.phase == PurchasePhase.restoring
                      ? null
                      : controller.restore,
                  child: Text(
                    state.phase == PurchasePhase.restoring
                        ? l10n.proRestoring
                        : l10n.proRestore,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
