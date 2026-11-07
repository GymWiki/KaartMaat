import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/l10n.dart';
import '../games/data/game_state.dart';
import '../games/games_registry.dart';
import 'result_image.dart';

String buildShareText(AppLocalizations l10n, GameView view) {
  final date = DateFormat('d MMM yyyy', 'nl')
      .format(view.state.finishedAt ?? view.state.createdAt);
  final game = definitionFor(view.state.type).name(l10n);
  return [
    l10n.shareHeader(game, date),
    for (final s in view.standings)
      l10n.shareTotalLine(s.rank, view.nameOf(s.participant), s.total),
  ].join('\n');
}

/// Renders [boundary] as a PNG at 3x (1080 px wide for the result card).
Future<Uint8List> renderPng(RenderRepaintBoundary boundary) async {
  final image = await boundary.toImage(pixelRatio: 3);
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  return data!.buffer.asUint8List();
}

/// Preview of the result picture with share and copy-text buttons.
Future<void> showShareResult(BuildContext context, GameView view) {
  return showDialog<void>(
    context: context,
    builder: (_) => _ShareDialog(view: view),
  );
}

class _ShareDialog extends StatefulWidget {
  const _ShareDialog({required this.view});
  final GameView view;

  @override
  State<_ShareDialog> createState() => _ShareDialogState();
}

class _ShareDialogState extends State<_ShareDialog> {
  final _key = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      final boundary =
          _key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final bytes = await renderPng(boundary);
      await SharePlus.instance.share(ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'image/png')],
        fileNameOverrides: const ['kaartmaat-uitslag.png'],
        text: buildShareText(l10n, widget.view),
      ));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _copy() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(
        ClipboardData(text: buildShareText(l10n, widget.view)));
    messenger.showSnackBar(SnackBar(content: Text(l10n.copied)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            FittedBox(
              child: RepaintBoundary(
                key: _key,
                child: ResultImageCard(view: widget.view),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _share,
                icon: const Icon(Icons.ios_share),
                label: Text(l10n.shareImage),
              ),
            ),
            TextButton(onPressed: _copy, child: Text(l10n.copyResult)),
          ]),
        ),
      ),
    );
  }
}
