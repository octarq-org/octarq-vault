import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

/// Opens [bytes] in a new browser tab via blob URL (images, PDF, etc.).
Future<void> previewDecryptedAttachment({
  required BuildContext context,
  required Uint8List bytes,
  required String mimeType,
  required String suggestedName,
}) async {
  if (!kIsWeb) return;
  final type = mimeType.isNotEmpty ? mimeType : 'application/octet-stream';
  final parts = [bytes.toJS].toJS;
  final blob = web.Blob(parts, web.BlobPropertyBag(type: type));
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..target = '_blank'
    ..rel = 'noopener noreferrer';
  web.document.body!.appendChild(anchor);
  anchor.click();
  web.document.body!.removeChild(anchor);
  Future<void>.delayed(const Duration(seconds: 2), () {
    web.URL.revokeObjectURL(url);
  });
}
