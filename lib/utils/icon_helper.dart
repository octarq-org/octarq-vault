import 'package:flutter/material.dart';

IconData getIconData(String iconName) {
  const map = {
    'language': Icons.language,
    'security': Icons.security,
    'dns': Icons.dns,
    'email': Icons.email,
    'account_circle': Icons.account_circle,
    'credit_card': Icons.credit_card,
    'vpn_key': Icons.vpn_key,
    'subscriptions': Icons.subscriptions,
    'currency_bitcoin': Icons.currency_bitcoin,
    'terminal': Icons.terminal,
    'key': Icons.key,
    'cloud': Icons.cloud,
    'shield': Icons.shield,
    'phone': Icons.phone,
    'web': Icons.web,
    'lock': Icons.lock,
  };
  return map[iconName] ?? Icons.category;
}

/// Returns a unique color for a given asset type id — used for avatar backgrounds.
Color getTypeColor(String typeId) {
  const colors = <Color>[
    Color(0xFF00C896), // emerald
    Color(0xFF6C63FF), // violet
    Color(0xFFFF6B6B), // coral
    Color(0xFFFFB74D), // amber
    Color(0xFF4FC3F7), // sky
    Color(0xFFBA68C8), // purple
    Color(0xFF4DB6AC), // teal
    Color(0xFFF06292), // pink
    Color(0xFF81C784), // green
    Color(0xFFFFD54F), // yellow
  ];
  final h = typeId.codeUnits.fold(0, (a, b) => a + b);
  return colors[h % colors.length];
}
