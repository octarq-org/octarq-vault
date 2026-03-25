// Conditional export: native IO on all non-web platforms, IndexedDB on web.
export 'attachment_service_io.dart'
    if (dart.library.js_interop) 'attachment_service_web.dart';
