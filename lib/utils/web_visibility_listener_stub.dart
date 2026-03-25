/// Web-only hook; no-op on VM/mobile/desktop.
void listenWebDocumentVisibility({
  required void Function() onBecameHidden,
  required void Function() onBecameVisible,
}) {}
