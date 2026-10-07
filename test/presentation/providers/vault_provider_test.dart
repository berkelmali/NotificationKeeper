import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/data/services/vault_service.dart';
import 'package:app/presentation/providers/vault_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.example.notification_keeper/notifications');
  late List<String> calls;
  late Object? status;
  late Object? unlockOutcome;
  late bool guardCreate;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls = [];
    status = 'ready';
    unlockOutcome = 'ok';
    guardCreate = true;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'biometricGuardCreate':
          return guardCreate;
        case 'biometricStatus':
          return status;
        case 'biometricUnlock':
          return unlockOutcome;
        case 'biometricGuardDelete':
        case 'openBiometricEnrollment':
          return true;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Future<VaultProvider> loaded() async {
    final vault = VaultProvider();
    await vault.load();
    return vault;
  }

  test('fingerprint unlock is never on without a PIN', () async {
    final vault = await loaded();
    await vault.enableBiometric();
    expect(vault.biometricEnabled, isFalse);
  });

  test('switching fingerprint unlock on arms the tripwire', () async {
    final vault = await loaded();
    await vault.setPin('1234');

    expect(await vault.enableBiometric(), isTrue);
    expect(vault.biometricEnabled, isTrue);
    expect(calls, contains('biometricGuardCreate'));
  });

  test('stays off when the phone has no fingerprint enrolled yet', () async {
    guardCreate = false;
    final vault = await loaded();
    await vault.setPin('1234');

    expect(await vault.enableBiometric(), isFalse);
    expect(vault.biometricEnabled, isFalse);
  });

  test('maps what the phone says about its fingerprint sensor', () async {
    final vault = await loaded();
    for (final entry in {
      'ready': BiometricStatus.ready,
      'none_enrolled': BiometricStatus.noneEnrolled,
      'unsupported': BiometricStatus.unsupported,
      null: BiometricStatus.unsupported, // no answer at all: never offer it
    }.entries) {
      status = entry.key;
      expect(await vault.biometricStatus(), entry.value, reason: '${entry.key}');
    }
  });

  test('maps how a fingerprint unlock ended', () async {
    final vault = await loaded();
    await vault.setPin('1234');
    for (final entry in {
      'ok': BiometricUnlockResult.ok,
      'cancelled': BiometricUnlockResult.cancelled,
      'invalidated': BiometricUnlockResult.invalidated,
      'lockout': BiometricUnlockResult.lockout,
      'unavailable': BiometricUnlockResult.unavailable,
      'something odd': BiometricUnlockResult.error,
      null: BiometricUnlockResult.error,
    }.entries) {
      unlockOutcome = entry.key;
      expect(
        await vault.unlockWithBiometrics(title: 'Unlock', cancelLabel: 'Use PIN'),
        entry.value,
        reason: '${entry.key}',
      );
    }
  });

  test('a fingerprint unlock clears earlier wrong PIN attempts', () async {
    final vault = await loaded();
    await vault.setPin('1234');
    for (var i = 0; i < VaultService.freeAttempts; i++) {
      await vault.verifyPin('0000');
    }
    expect(vault.lockoutRemaining, isNotNull);

    unlockOutcome = 'ok';
    await vault.unlockWithBiometrics(title: 'Unlock', cancelLabel: 'Use PIN');
    expect(vault.lockoutRemaining, isNull);
  });

  test('a cancelled fingerprint prompt leaves the PIN lockout alone', () async {
    final vault = await loaded();
    await vault.setPin('1234');
    for (var i = 0; i < VaultService.freeAttempts; i++) {
      await vault.verifyPin('0000');
    }
    unlockOutcome = 'cancelled';
    await vault.unlockWithBiometrics(title: 'Unlock', cancelLabel: 'Use PIN');
    expect(vault.lockoutRemaining, isNotNull);
  });

  test('a trip to fingerprint settings is reported once, on the way back', () async {
    final vault = await loaded();
    expect(vault.takeEnrollmentTrip(), isFalse);

    await vault.openEnrollment();
    expect(calls, contains('openBiometricEnrollment'));
    expect(vault.takeEnrollmentTrip(), isTrue);
    expect(vault.takeEnrollmentTrip(), isFalse, reason: 'only the first return counts');
  });

  test('turning the vault off removes the PIN, fingerprint unlock and tripwire', () async {
    final vault = await loaded();
    await vault.setPin('1234');
    await vault.enableBiometric();

    await vault.disable();

    expect(vault.hasPin, isFalse);
    expect(vault.biometricEnabled, isFalse);
    expect(calls, contains('biometricGuardDelete'));
  });

  test('fingerprint preference survives a restart', () async {
    final vault = await loaded();
    await vault.setPin('1234');
    await vault.enableBiometric();

    final reopened = await loaded();
    expect(reopened.hasPin, isTrue);
    expect(reopened.biometricEnabled, isTrue);
  });
}
