import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/l10n.dart';
import 'purchase_service.dart';

Future<void> showUnlockSheet(BuildContext context, WidgetRef ref) {
  final service = ref.read(purchaseServiceProvider);
  final messenger = ScaffoldMessenger.of(context);
  final l10n = context.l10n;
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.unlockTitle,
                style: Theme.of(sheet).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(l10n.unlockBody(service.priceLabel)),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                final ok = await service.purchase();
                if (sheet.mounted) Navigator.pop(sheet);
                if (ok) messenger.showSnackBar(SnackBar(content: Text(l10n.unlockedDone)));
              },
              child: Text(l10n.unlockBuy(service.priceLabel)),
            ),
            TextButton(
              onPressed: () async {
                final ok = await service.restore();
                if (sheet.mounted) Navigator.pop(sheet);
                messenger.showSnackBar(SnackBar(
                    content: Text(ok ? l10n.unlockedDone : l10n.restoreNone)));
              },
              child: Text(l10n.restorePurchases),
            ),
          ],
        ),
      ),
    ),
  );
}
