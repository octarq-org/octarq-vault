import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

Widget buildWebGoogleSignInButton({VoidCallback? onPressedIfNative}) {
  return web.renderButton(
    configuration: web.GSIButtonConfiguration(
      theme: web.GSIButtonTheme.outline,
      type: web.GSIButtonType.standard,
    ),
  );
}
