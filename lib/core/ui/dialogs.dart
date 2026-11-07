import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

Future<bool> confirmDialog(
  BuildContext context,
  String message, {
  String? actionLabel,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(actionLabel ?? context.l10n.confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Asks for a whole number. Returns null when cancelled.
Future<int?> intDialog(
  BuildContext context, {
  required String title,
  required int initial,
  required int min,
  required int max,
}) {
  final controller = TextEditingController(text: '$initial');
  return showDialog<int>(
    context: context,
    builder: (context) {
      void submit() {
        final v = int.tryParse(controller.text.trim());
        if (v != null) Navigator.pop(context, v.clamp(min, max));
      }

      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          onSubmitted: (_) => submit(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel),
          ),
          TextButton(onPressed: submit, child: Text(context.l10n.save)),
        ],
      );
    },
  );
}
