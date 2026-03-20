import 'package:flutter_test/flutter_test.dart';
import 'package:octarq_vault/utils/auto_lock.dart';

void main() {
  group('shouldLockAfterBackground', () {
    test('false when under the minute threshold', () {
      final paused = DateTime(2025, 3, 20, 12, 0, 0);
      final now = DateTime(2025, 3, 20, 12, 4, 59);
      expect(
        shouldLockAfterBackground(pausedAt: paused, now: now, limitMinutes: 5),
        isFalse,
      );
    });

    test('true when elapsed whole minutes meet threshold', () {
      final paused = DateTime(2025, 3, 20, 12, 0, 0);
      final now = DateTime(2025, 3, 20, 12, 5, 0);
      expect(
        shouldLockAfterBackground(pausedAt: paused, now: now, limitMinutes: 5),
        isTrue,
      );
    });

    test('zero-minute policy locks after any positive background gap', () {
      final paused = DateTime(2025, 3, 20, 12, 0, 0);
      final now = DateTime(2025, 3, 20, 12, 0, 0, 1);
      expect(
        shouldLockAfterBackground(pausedAt: paused, now: now, limitMinutes: 0),
        isTrue,
      );
    });
  });
}
