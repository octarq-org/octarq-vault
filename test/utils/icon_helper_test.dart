import 'package:flutter_test/flutter_test.dart';
import 'package:octarq_vault/utils/icon_helper.dart';
import 'package:flutter/material.dart';

void main() {
  group('getIconData', () {
    test('returns correct icon for language', () {
      expect(getIconData('language'), equals(Icons.language));
    });

    test('returns correct icon for security', () {
      expect(getIconData('security'), equals(Icons.security));
    });

    test('returns correct icon for dns', () {
      expect(getIconData('dns'), equals(Icons.dns));
    });

    test('returns correct icon for email', () {
      expect(getIconData('email'), equals(Icons.email));
    });

    test('returns correct icon for account_circle', () {
      expect(getIconData('account_circle'), equals(Icons.account_circle));
    });

    test('returns correct icon for credit_card', () {
      expect(getIconData('credit_card'), equals(Icons.credit_card));
    });

    test('returns correct icon for vpn_key', () {
      expect(getIconData('vpn_key'), equals(Icons.vpn_key));
    });

    test('returns correct icon for subscriptions', () {
      expect(getIconData('subscriptions'), equals(Icons.subscriptions));
    });

    test('returns category icon for unknown names', () {
      expect(getIconData('unknown'), equals(Icons.category));
      expect(getIconData(''), equals(Icons.category));
      expect(getIconData('random_icon'), equals(Icons.category));
    });
  });
}
