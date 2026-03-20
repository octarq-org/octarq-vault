// Conditional export: native IO on all non-web platforms, stub on web.
export 'attachment_service_io.dart'
    if (dart.library.js_interop) 'attachment_service_stub.dart';
