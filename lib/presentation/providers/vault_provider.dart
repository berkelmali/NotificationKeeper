import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/services/vault_service.dart';

/// Whether this phone can unlock the vault with a fingerprint.
enum BiometricStatus {
  /// A strong biometric is enrolled and can be used.
  ready,

  /// The hardware is there, but no fingerprint is saved on the phone yet.
  noneEnrolled,

  /// No strong biometric hardware (weak face unlock does not count).
  unsupported,
}

/// How a fingerprint unlock attempt ended.
enum BiometricUnlockResult {
  ok,

  /// Closed by the user or the system; the PIN pad is still there.
  cancelled,

  /// A fingerprint was added to the phone since fingerprint unlock was
  /// switched on, or its key is gone: the PIN is needed before fingerprints
  /// count again.
  invalidated,

  /// Android stopped accepting fingerprints for a while after failed tries.
  lockout,

  /// The sensor is unavailable, or no fingerprint is enrolled any more.
  unavailable,

  error,
}

/// The vault: an app PIN as the "registration", fingerprints as a convenience
/// on top. Fingerprint unlock goes through a Keystore key that Android destroys
/// when another fingerprint is enrolled, so a newly added finger never opens
/// the vault until the PIN has been entered.
///
/// Installs from before the PIN existed may still have the old biometric-only
/// lock switched on ([SettingsProvider.biometricLockEnabled]); that keeps
/// working, and the lock screen invites those users to create a PIN.
class VaultProvider extends ChangeNotifier {
  VaultProvider({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel('com.example.notification_keeper/notifications');

  final MethodChannel _channel;
  VaultService? _service;
  SharedPreferences? _prefs;
  bool _biometricEnabled = false;
  bool _enrollmentTrip = false;

  static const _kBiometric = 'vaultBiometricEnabled';

  bool get isLoaded => _service != null;
  bool get hasPin => _service?.hasPin ?? false;

  /// Biometric unlock is only ever offered on top of a PIN.
  bool get biometricEnabled => hasPin && _biometricEnabled;

  Duration? get lockoutRemaining => _service?.lockoutRemaining();

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _service = VaultService(_prefs!);
    _biometricEnabled = _prefs!.getBool(_kBiometric) ?? false;
    notifyListeners();
  }

  VaultService get _vault {
    final service = _service;
    if (service == null) throw StateError('VaultProvider.load() has not run');
    return service;
  }

  /// Creates the PIN (or replaces it after "forgot PIN" / "change PIN").
  Future<void> setPin(String pin) async {
    await _vault.setPin(pin);
    notifyListeners();
  }

  Future<PinCheck> verifyPin(String pin) async {
    final check = await _vault.verifyPin(pin);
    notifyListeners();
    return check;
  }

  /// Turns the vault off entirely: PIN, biometric unlock and the tripwire.
  Future<void> disable() async {
    await _vault.clearPin();
    await disableBiometric();
  }

  /// Switches fingerprint unlock on by creating its key. False when the phone
  /// cannot hold the key yet - usually because no fingerprint is enrolled.
  Future<bool> enableBiometric() async {
    final ok = await _invoke<bool>('biometricGuardCreate') ?? false;
    if (ok) {
      _biometricEnabled = true;
      await _prefs?.setBool(_kBiometric, true);
      notifyListeners();
    }
    return ok;
  }

  Future<void> disableBiometric() async {
    _biometricEnabled = false;
    await _prefs?.setBool(_kBiometric, false);
    await _invoke<bool>('biometricGuardDelete');
    notifyListeners();
  }

  Future<BiometricStatus> biometricStatus() async {
    switch (await _invoke<String>('biometricStatus')) {
      case 'ready':
        return BiometricStatus.ready;
      case 'none_enrolled':
        return BiometricStatus.noneEnrolled;
      default:
        return BiometricStatus.unsupported;
    }
  }

  /// Shows Android's fingerprint prompt, bound to the vault's key.
  Future<BiometricUnlockResult> unlockWithBiometrics({
    required String title,
    String? subtitle,
    required String cancelLabel,
  }) async {
    final outcome = await _invoke<String>('biometricUnlock', {
      'title': title,
      'subtitle': subtitle,
      'cancel': cancelLabel,
    });
    switch (outcome) {
      case 'ok':
        // A fingerprint that was on the phone when fingerprint unlock was set
        // up proves it is the owner, just as the right PIN does.
        await _vault.resetAttempts();
        return BiometricUnlockResult.ok;
      case 'cancelled':
        return BiometricUnlockResult.cancelled;
      case 'invalidated':
        return BiometricUnlockResult.invalidated;
      case 'lockout':
        return BiometricUnlockResult.lockout;
      case 'unavailable':
        return BiometricUnlockResult.unavailable;
      default:
        return BiometricUnlockResult.error;
    }
  }

  /// Keeps the archive out of the app switcher's thumbnail (Android 13+).
  Future<void> setRecentsPreviewHidden(bool hidden) async {
    await _invoke<bool>('setRecentsPreviewHidden', {'hidden': hidden});
  }

  /// Sends the user to Android's own "add a fingerprint" screen.
  Future<bool> openEnrollment() async {
    _enrollmentTrip = true;
    final opened = await _invoke<bool>('openBiometricEnrollment') ?? false;
    if (!opened) _enrollmentTrip = false;
    return opened;
  }

  /// Whether the app is coming back from a trip to Android's fingerprint
  /// settings that it started itself. Answers true once per trip.
  bool takeEnrollmentTrip() {
    final trip = _enrollmentTrip;
    _enrollmentTrip = false;
    return trip;
  }

  Future<T?> _invoke<T>(String method, [Map<String, Object?>? arguments]) async {
    try {
      return await _channel.invokeMethod<T>(method, arguments);
    } on PlatformException catch (e) {
      debugPrint('Vault call $method failed: ${e.message}');
      return null;
    } on MissingPluginException {
      return null;
    }
  }
}
