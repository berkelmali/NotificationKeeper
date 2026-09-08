import 'package:flutter_test/flutter_test.dart';
import 'package:app/presentation/screens/biometric_lock_screen.dart';

/// The vault used to unlock once per app process: anything that reached the app
/// switcher, or reopening the app hours later without the OS having killed it,
/// showed the archive with no authentication. These cover the timing rule that
/// fixed it, without standing up a fake biometric platform channel.
void main() {
  final now = DateTime(2026, 9, 9, 12, 0, 0);

  group('BiometricLockScreen.shouldRelock', () {
    test('never re-locks when the app was not backgrounded while unlocked', () {
      // Also the state while the system biometric sheet is up: that only ever
      // appears while still locked, so it must not arm the timer.
      expect(BiometricLockScreen.shouldRelock(null, now), false);
    });

    test('does not re-lock for a quick trip to another app', () {
      final since = now.subtract(const Duration(seconds: 5));
      expect(BiometricLockScreen.shouldRelock(since, now), false);
    });

    test('does not re-lock one second before the grace period ends', () {
      final since = now.subtract(BiometricLockScreen.relockAfter -
          const Duration(seconds: 1));
      expect(BiometricLockScreen.shouldRelock(since, now), false);
    });

    test('re-locks exactly at the grace period boundary', () {
      final since = now.subtract(BiometricLockScreen.relockAfter);
      expect(BiometricLockScreen.shouldRelock(since, now), true);
    });

    test('re-locks after a long time away', () {
      final since = now.subtract(const Duration(hours: 8));
      expect(BiometricLockScreen.shouldRelock(since, now), true);
    });

    test('the grace period is short enough to be a real lock, but long enough '
        'to survive switching apps to type a captured code', () {
      expect(BiometricLockScreen.relockAfter.inSeconds, greaterThan(0));
      expect(BiometricLockScreen.relockAfter.inMinutes, lessThanOrEqualTo(1));
    });
  });
}
