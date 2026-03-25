import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Registers [document.visibilitychange] so tab / window hiding counts as
/// “background” (Flutter Web often never fires [AppLifecycleState.paused]).
void listenWebDocumentVisibility({
  required void Function() onBecameHidden,
  required void Function() onBecameVisible,
}) {
  if (!kIsWeb) return;

  void handle(web.Event _) {
    if (web.document.hidden) {
      onBecameHidden();
    } else {
      onBecameVisible();
    }
  }

  web.document.onvisibilitychange = handle.toJS;
}
