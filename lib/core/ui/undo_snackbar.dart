import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// "Ronde 3 opgeslagen · Ongedaan maken" without a dialog. Floats above the
/// input panel (see `GameScreenScaffold.panelInsetOf`) so it never covers the
/// buttons in the thumb zone.
class UndoSnackbar {
  static const duration = Duration(seconds: 5);

  static void show(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    double bottomInset = 0,
    VoidCallback? onFeedback,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 12),
        action: SnackBarAction(
          label: context.l10n.undoAction,
          onPressed: () {
            onFeedback?.call();
            onUndo();
          },
        ),
      ));
  }
}
