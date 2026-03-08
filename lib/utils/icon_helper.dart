import 'package:flutter/material.dart';

IconData getIconData(String iconName) {
  switch (iconName) {
    case 'language':
      return Icons.language;
    case 'security':
      return Icons.security;
    case 'dns':
      return Icons.dns;
    case 'email':
      return Icons.email;
    case 'account_circle':
      return Icons.account_circle;
    case 'credit_card':
      return Icons.credit_card;
    case 'vpn_key':
      return Icons.vpn_key;
    case 'subscriptions':
      return Icons.subscriptions;
    default:
      return Icons.category;
  }
}
