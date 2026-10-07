import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:app/data/services/vault_service.dart';
import 'package:app/l10n/generated/app_localizations.dart';
import 'package:app/presentation/providers/settings_provider.dart';
import 'package:app/presentation/providers/vault_provider.dart';
import 'package:app/presentation/screens/vault_lock_screen.dart';

/// A vault with a known PIN and no fingerprint unlock, so the lock can be
/// driven without the platform channel or the PBKDF2 isolate (both covered
/// by their own tests).
class _FakeVault extends VaultProvider {
  _FakeVault({this.pin});

  String? pin;
  int _wrong = 0;

  @override
  bool get hasPin => pin != null;

  @override
  bool get biometricEnabled => false;

  @override
  Duration? get lockoutRemaining => null;

  @override
  Future<PinCheck> verifyPin(String candidate) async {
    if (candidate == pin) return const PinCheck(PinCheckResult.ok);
    _wrong++;
    return PinCheck(PinCheckResult.wrong, attemptsLeft: VaultService.freeAttempts - _wrong);
  }

  @override
  Future<void> setRecentsPreviewHidden(bool hidden) async {}

  void turnOn(String newPin) {
    pin = newPin;
    notifyListeners();
  }
}

void main() {
  final now = DateTime(2026, 9, 9, 12, 0, 0);

  group('VaultLockScreen.shouldRelock', () {
    test('never re-locks when the app was not backgrounded while unlocked', () {
      expect(VaultLockScreen.shouldRelock(null, now), false);
    });

    test('does not re-lock for a quick trip to another app', () {
      final since = now.subtract(const Duration(seconds: 5));
      expect(VaultLockScreen.shouldRelock(since, now), false);
    });

    test('does not re-lock one second before the grace period ends', () {
      final since = now.subtract(VaultLockScreen.defaultRelockAfter - const Duration(seconds: 1));
      expect(VaultLockScreen.shouldRelock(since, now), false);
    });

    test('re-locks exactly at the grace period boundary', () {
      final since = now.subtract(VaultLockScreen.defaultRelockAfter);
      expect(VaultLockScreen.shouldRelock(since, now), true);
    });

    test('re-locks after a long time away', () {
      final since = now.subtract(const Duration(hours: 8));
      expect(VaultLockScreen.shouldRelock(since, now), true);
    });

    test('the grace period is short enough to be a real lock, but long enough '
        'to survive switching apps to type a captured code', () {
      expect(VaultLockScreen.defaultRelockAfter.inSeconds, greaterThan(0));
      expect(VaultLockScreen.defaultRelockAfter.inMinutes, lessThanOrEqualTo(1));
    });

    test('a trip to fingerprint settings gets longer, but not forever', () {
      final since = now.subtract(const Duration(minutes: 3));
      expect(VaultLockScreen.shouldRelock(since, now, after: VaultLockScreen.enrollmentTripAllowance), false);
      expect(VaultLockScreen.enrollmentTripAllowance.inMinutes, lessThanOrEqualTo(15));
    });
  });

  group('The lock over the app', () {
    late GlobalKey<NavigatorState> navigatorKey;

    Future<void> pumpApp(
      WidgetTester tester,
      _FakeVault vault, {
      Duration relockAfter = VaultLockScreen.defaultRelockAfter,
    }) async {
      navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<VaultProvider>.value(value: vault),
          ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ],
        child: MaterialApp(
          navigatorKey: navigatorKey,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, navigator) => VaultLockScreen(
            navigatorKey: navigatorKey,
            relockAfter: relockAfter,
            child: navigator!,
          ),
          home: const Scaffold(body: Text('Archive home')),
        ),
      ));
      await tester.pump();
    }

    Future<void> enterPin(WidgetTester tester, String pin) async {
      for (final digit in pin.split('')) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }
      await tester.tap(find.text('Unlock'));
      await tester.pump();
      await tester.pump();
    }

    Future<void> leaveAndComeBack(WidgetTester tester) async {
      for (final state in const [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
      for (final state in const [
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pump();
    }

    testWidgets('locks on start when the vault has a PIN', (tester) async {
      await pumpApp(tester, _FakeVault(pin: '1234'));
      expect(find.text('Vault locked'), findsOneWidget);
      expect(find.text('Archive home'), findsNothing);
    });

    testWidgets('stays out of the way while the vault is off', (tester) async {
      await pumpApp(tester, _FakeVault());
      expect(find.text('Archive home'), findsOneWidget);
      expect(find.text('Vault locked'), findsNothing);
    });

    testWidgets('the right PIN opens the app; a wrong one says how many tries are left', (tester) async {
      await pumpApp(tester, _FakeVault(pin: '1234'));

      await enterPin(tester, '9999');
      expect(find.text('Wrong PIN. 4 attempts left'), findsOneWidget);
      expect(find.text('Archive home'), findsNothing);

      for (var i = 0; i < 3; i++) {
        await enterPin(tester, '9999');
      }
      expect(find.text('Wrong PIN. 1 attempt left'), findsOneWidget);

      await enterPin(tester, '1234');
      expect(find.text('Archive home'), findsOneWidget);
      expect(find.text('Vault locked'), findsNothing);
    });

    testWidgets('re-locking also hides a screen left open on top, and unlocking returns to it', (tester) async {
      await pumpApp(tester, _FakeVault(pin: '1234'), relockAfter: Duration.zero);
      await enterPin(tester, '1234');

      navigatorKey.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('Recalled photo')),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Recalled photo'), findsOneWidget);

      await leaveAndComeBack(tester);
      expect(find.text('Recalled photo'), findsNothing);
      expect(find.text('Vault locked'), findsOneWidget);

      await enterPin(tester, '1234');
      expect(find.text('Recalled photo'), findsOneWidget, reason: 'unlocking returns to the same screen');
    });

    testWidgets('a quick trip away does not ask for the PIN again', (tester) async {
      await pumpApp(tester, _FakeVault(pin: '1234'));
      await enterPin(tester, '1234');

      await leaveAndComeBack(tester);
      expect(find.text('Archive home'), findsOneWidget);
      expect(find.text('Vault locked'), findsNothing);
    });

    testWidgets('switching the vault on does not lock you out of the screen you are on', (tester) async {
      final vault = _FakeVault();
      await pumpApp(tester, vault);

      vault.turnOn('1234');
      await tester.pump();
      expect(find.text('Archive home'), findsOneWidget);
      expect(find.text('Vault locked'), findsNothing);
    });
  });
}
