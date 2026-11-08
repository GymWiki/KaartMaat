import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';

import 'share_result_card.dart';

/// Renders the on-screen card ([boundary] around a [ShareResultCard]) to a
/// PNG of exactly 1080 x 1350 px, whatever the scale of the preview.
Future<Uint8List> renderCardPng(RenderRepaintBoundary boundary) async {
  final image = await boundary.toImage(
    pixelRatio: 1080 / ShareResultCard.width,
  );
  try {
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data!.buffer.asUint8List();
  } finally {
    image.dispose();
  }
}

/// Shares the picture with the system share sheet (WhatsApp is the main
/// target). The file is written to a temporary folder and removed again.
/// share_plus keeps its own copy of a shared file in the cache folder (the
/// receiving app reads it after we are done), so that copy is removed at the
/// start of the next share instead of right away.
Future<void> _removeStaleShares() async {
  try {
    final stale = Directory('${Directory.systemTemp.path}/share_plus');
    if (await stale.exists()) await stale.delete(recursive: true);
  } catch (_) {}
}

Future<void> shareCardPng(Uint8List bytes, String caption) async {
  Directory? dir;
  await _removeStaleShares();
  try {
    XFile file;
    try {
      dir = await Directory.systemTemp.createTemp('kaartmaat_share');
      final f = File('${dir.path}/kaartmaat-uitslag.png');
      await f.writeAsBytes(bytes, flush: true);
      file = XFile(f.path, mimeType: 'image/png');
    } catch (_) {
      // no usable temp folder: let share_plus handle the bytes itself
      file = XFile.fromData(bytes, mimeType: 'image/png');
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: const ['kaartmaat-uitslag.png'],
        text: caption,
      ),
    );
  } finally {
    try {
      await dir?.delete(recursive: true);
    } catch (_) {}
  }
}

enum SaveResult { saved, denied, failed }

/// Stores the picture in the gallery (album "Kaartmaat"). Modern Android
/// needs no permission for this; older versions and iOS ask once.
Future<SaveResult> saveCardPng(Uint8List bytes) async {
  try {
    if (!await Gal.hasAccess(toAlbum: true)) {
      if (!await Gal.requestAccess(toAlbum: true)) return SaveResult.denied;
    }
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await Gal.putImageBytes(
      bytes,
      name: 'kaartmaat-uitslag-$stamp',
      album: 'Kaartmaat',
    );
    return SaveResult.saved;
  } on GalException catch (e) {
    return e.type == GalExceptionType.accessDenied
        ? SaveResult.denied
        : SaveResult.failed;
  } catch (_) {
    return SaveResult.failed;
  }
}
