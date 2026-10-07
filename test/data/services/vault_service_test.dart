import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/data/services/vault_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  final t0 = DateTime(2026, 10, 4, 12);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('PIN format', () {
    test('accepts 4 to 8 digits only', () {
      expect(VaultService.isValidPin('1234'), isTrue);
      expect(VaultService.isValidPin('12345678'), isTrue);
      expect(VaultService.isValidPin('123'), isFalse);
      expect(VaultService.isValidPin('123456789'), isFalse);
      expect(VaultService.isValidPin('12a4'), isFalse);
      expect(VaultService.isValidPin(''), isFalse);
    });

    test('refuses to store an invalid PIN', () {
      expect(() => VaultService(prefs).setPin('12'), throwsArgumentError);
    });
  });

  group('Registration and verification', () {
    test('the right PIN opens the vault, a wrong one does not', () async {
      final vault = VaultService(prefs);
      await vault.setPin('482913');

      expect(vault.hasPin, isTrue);
      expect((await vault.verifyPin('482913', now: t0)).isOk, isTrue);
      expect((await vault.verifyPin('000000', now: t0)).result, PinCheckResult.wrong);
    });

    test('the PIN itself is never stored, only a salted hash', () async {
      await VaultService(prefs).setPin('482913');
      for (final key in prefs.getKeys()) {
        expect(prefs.get(key).toString(), isNot(contains('482913')), reason: key);
      }
    });

    test('the same PIN set twice gets a different salt and hash', () async {
      final vault = VaultService(prefs);
      await vault.setPin('1111');
      final firstHash = prefs.getString('vaultPinHash');
      await vault.setPin('1111');
      expect(prefs.getString('vaultPinHash'), isNot(firstHash));
      expect((await vault.verifyPin('1111', now: t0)).isOk, isTrue);
    });

    test('clearPin turns the vault off', () async {
      final vault = VaultService(prefs);
      await vault.setPin('1234');
      await vault.clearPin();
      expect(vault.hasPin, isFalse);
    });
  });

  group('Attempt limit', () {
    test('counts down the free attempts', () async {
      final vault = VaultService(prefs);
      await vault.setPin('1234');

      final first = await vault.verifyPin('0000', now: t0);
      expect(first.result, PinCheckResult.wrong);
      expect(first.attemptsLeft, VaultService.freeAttempts - 1);
    });

    test('locks out after the free attempts, even for the right PIN', () async {
      final vault = VaultService(prefs);
      await vault.setPin('1234');
      PinCheck? last;
      for (var i = 0; i < VaultService.freeAttempts; i++) {
        last = await vault.verifyPin('0000', now: t0);
      }
      expect(last!.result, PinCheckResult.lockedOut);
      expect(last.retryIn, VaultService.lockoutSteps.first);

      final during = await vault.verifyPin('1234', now: t0.add(const Duration(seconds: 10)));
      expect(during.result, PinCheckResult.lockedOut);
    });

    test('the right PIN after the lockout opens and resets the counter', () async {
      final vault = VaultService(prefs);
      await vault.setPin('1234');
      for (var i = 0; i < VaultService.freeAttempts; i++) {
        await vault.verifyPin('0000', now: t0);
      }
      final after = t0.add(VaultService.lockoutSteps.first + const Duration(seconds: 1));
      expect((await vault.verifyPin('1234', now: after)).isOk, isTrue);
      expect(vault.failedAttempts, 0);
      expect(vault.lockoutRemaining(after), isNull);
    });

    test('each further wrong attempt locks out for longer', () async {
      final vault = VaultService(prefs);
      await vault.setPin('1234');
      var now = t0;
      for (var i = 0; i < VaultService.freeAttempts; i++) {
        await vault.verifyPin('0000', now: now);
      }
      now = now.add(VaultService.lockoutSteps[0] + const Duration(seconds: 1));
      final second = await vault.verifyPin('0000', now: now);
      expect(second.retryIn, VaultService.lockoutSteps[1]);
    });

    test('a restart does not reset the lockout', () async {
      await VaultService(prefs).setPin('1234');
      for (var i = 0; i < VaultService.freeAttempts; i++) {
        await VaultService(prefs).verifyPin('0000', now: t0);
      }
      // A fresh instance over the same storage, as after killing the app.
      final reopened = VaultService(prefs);
      expect(reopened.lockoutRemaining(t0.add(const Duration(seconds: 5))), isNotNull);
      final check = await reopened.verifyPin('1234', now: t0.add(const Duration(seconds: 5)));
      expect(check.result, PinCheckResult.lockedOut);
    });
  });
}
