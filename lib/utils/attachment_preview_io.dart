import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> previewDecryptedAttachment({
  required BuildContext context,
  required Uint8List bytes,
  required String mimeType,
  required String suggestedName,
}) async {
  final mt = mimeType.toLowerCase();
  if (mt.startsWith('image/')) {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900, maxHeight: 900),
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Image.memory(bytes),
          ),
        ),
      ),
    );
    return;
  }

  final dir = await getTemporaryDirectory();
  final base = p.basename(suggestedName);
  final safe = base.replaceAll(RegExp(r'[^\w.\- ]'), '_');
  final file = File('${dir.path}/octarq_preview_$safe');
  await file.writeAsBytes(bytes, flush: true);
  final uri = Uri.file(file.path);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    throw Exception('Could not open preview (launchUrl returned false)');
  }
}
