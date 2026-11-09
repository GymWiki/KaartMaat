import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/l10n.dart';
import '../../pro/entitlement_service.dart';
import '../../pro/purchase_controller.dart';

/// The Pro card at the top of Instellingen. It uses the same purchase logic
/// as the Pro wall (PurchaseController); it only looks different.
class ProCard extends ConsumerWidget {
  const ProCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final isPro = ref.watch(entitlementProvider);
    final state = ref.watch(purchaseControllerProvider);
    final controller = ref.read(purchaseControllerProvider.notifier);

    // "Bedankt!" once, right after a purchase went through.
    ref.listen(purchaseControllerProvider.select((s) => s.notice), (_, notice) {
      if (notice == PurchaseNotice.thanks) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.proThanks)));
        controller.clearNotice();
      }
    });

    final card = Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: isPro ? _active(l10n, text, scheme) : _offer(
          context, l10n, text, scheme, state, controller,
        ),
      ),
    );
    return card;
  }

  Widget _active(AppLocalizations l10n, TextTheme text, ColorScheme scheme) =>
      Row(
        children: [
          Icon(Icons.verified, color: scheme.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(l10n.proActive, style: text.titleMedium),
            ),
          ),
        ],
      );

  Widget _offer(
    BuildContext context,
    AppLocalizations l10n,
    TextTheme text,
    ColorScheme scheme,
    PurchaseState state,
    PurchaseController controller,
  ) {
    final busy = state.phase != PurchasePhase.idle;
    final notice = switch (state.notice) {
      PurchaseNotice.pending => (l10n.proPending, false),
      PurchaseNotice.failed => (l10n.proFailed, true),
      PurchaseNotice.restoreNone => (l10n.proRestoreNone, false),
      _ => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(l10n.proTitle, style: text.titleLarge)),
        const SizedBox(height: 4),
        Text(l10n.proCardText, style: text.bodyMedium),
        const SizedBox(height: 12),
        if (state.product != null)
          Text(
            '${state.product!.price} · ${l10n.proOnce}',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          )
        else if (state.loadingProduct)
          Text(l10n.proLoadingPrice, style: text.bodyMedium)
        else ...[
          Text(
            l10n.proProductError,
            style: text.bodyMedium?.copyWith(color: scheme.error),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: controller.loadProduct,
              child: Text(l10n.proRetry),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: state.product == null || busy ? null : controller.buy,
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
            padding: const EdgeInsets.only(top: 8),
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
        TextButton(
          onPressed: state.phase == PurchasePhase.purchasing ||
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
    );
  }
}
