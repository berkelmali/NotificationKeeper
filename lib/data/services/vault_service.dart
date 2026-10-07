import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart' as pc;
import 'package:shared_preferences/shared_preferences.dart';

/// Outcome of a PIN check.
enum PinCheckResult { ok, wrong, lockedOut }

class PinCheck {
  final PinCheckResult result;

  /// While locked out: how long until the next attempt is allowed.
  final Duration? retryIn;

  /// Wrong attempts still allowed before the next lockout starts.
  final int attemptsLeft;

  const PinCheck(this.result, {this.retryIn, this.attemptsLeft = 0});

  bool get isOk => result == PinCheckResult.ok;
}

/// The vault PIN: the app's own secret, created when the vault is set up.
///
/// Android does not let apps enrol or store fingerprints - those live in
/// secure hardware and an app only ever learns "a fingerprint enrolled on this
/// phone matched". So the vault's "registration" is this PIN, and biometrics
/// are a convenience on top of it.
///
/// The PIN is never stored, only a salted PBKDF2-HMAC-SHA256 hash. A 4-8 digit
/// PIN is a small keyspace, so hashing alone cannot make it strong against
/// someone who has extracted the app's private storage (which needs root); the
/// real protection against guessing is the attempt limit below, which survives
/// restarts because it is persisted.
///
/// The vault is an access lock for the app. The archive itself sits in
/// Android's app-private storage and is not separately encrypted.
class VaultService {
  VaultService(this._prefs);

  final SharedPreferences _prefs;

  static const int minPinLength = 4;
  static const int maxPinLength = 8;

  /// Enough to cost a guesser real work, low enough that unlocking stays well
  /// under half a second on a mid-range phone (PBKDF2 here is pure Dart).
  static const int pbkdf2Iterations = 30000;

  /// Wrong attempts allowed before the first lockout.
  static const int freeAttempts = 5;

  /// Lockout after each further wrong attempt, escalating, capped at the last.
  static const List<Duration> lockoutSteps = [
    Duration(seconds: 30),
    Duration(minutes: 1),
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(hours: 1),
  ];

  static const _kHash = 'vaultPinHash';
  static const _kSalt = 'vaultPinSalt';
  static const _kIterations = 'vaultPinIterations';
  static const _kFailed = 'vaultFailedAttempts';
  static const _kLockedUntil = 'vaultLockedUntil';

  bool get hasPin => _prefs.getString(_kHash) != null;

  int get failedAttempts => _prefs.getInt(_kFailed) ?? 0;

  static bool isValidPin(String pin) =>
      pin.length >= minPinLength &&
      pin.length <= maxPinLength &&
      RegExp(r'^\d+$').hasMatch(pin);

  /// Stores a new PIN (replacing any previous one) and clears the lockout.
  Future<void> setPin(String pin) async {
    if (!isValidPin(pin)) {
      throw ArgumentError('A vault PIN is $minPinLength-$maxPinLength digits');
    }
    final salt = _randomBytes(16);
    final hash = await _hash(pin, salt, pbkdf2Iterations);
    await _prefs.setString(_kHash, base64Encode(hash));
    await _prefs.setString(_kSalt, base64Encode(salt));
    await _prefs.setInt(_kIterations, pbkdf2Iterations);
    await resetAttempts();
  }

  /// Checks a PIN, enforcing the attempt limit.
  Future<PinCheck> verifyPin(String pin, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final wait = lockoutRemaining(at);
    if (wait != null) return PinCheck(PinCheckResult.lockedOut, retryIn: wait);

    final storedHash = _prefs.getString(_kHash);
    final storedSalt = _prefs.getString(_kSalt);
    if (storedHash == null || storedSalt == null) {
      return const PinCheck(PinCheckResult.wrong);
    }
    final iterations = _prefs.getInt(_kIterations) ?? pbkdf2Iterations;
    final candidate = await _hash(pin, base64Decode(storedSalt), iterations);

    if (_constantTimeEquals(candidate, base64Decode(storedHash))) {
      await resetAttempts();
      return const PinCheck(PinCheckResult.ok);
    }

    final failed = failedAttempts + 1;
    await _prefs.setInt(_kFailed, failed);
    if (failed >= freeAttempts) {
      final step = (failed - freeAttempts).clamp(0, lockoutSteps.length - 1);
      final lockout = lockoutSteps[step];
      await _prefs.setInt(_kLockedUntil, at.add(lockout).millisecondsSinceEpoch);
      return PinCheck(PinCheckResult.lockedOut, retryIn: lockout);
    }
    return PinCheck(PinCheckResult.wrong, attemptsLeft: freeAttempts - failed);
  }

  /// Time left on the current lockout, or null when an attempt is allowed.
  Duration? lockoutRemaining([DateTime? now]) {
    final until = _prefs.getInt(_kLockedUntil);
    if (until == null) return null;
    final left = DateTime.fromMillisecondsSinceEpoch(until).difference(now ?? DateTime.now());
    return left > Duration.zero ? left : null;
  }

  /// Removes the PIN (vault turned off, or reset after "forgot PIN").
  Future<void> clearPin() async {
    await _prefs.remove(_kHash);
    await _prefs.remove(_kSalt);
    await _prefs.remove(_kIterations);
    await resetAttempts();
  }

  /// Clears the wrong-attempt count and any lockout - after the owner has
  /// proved who they are some other way.
  Future<void> resetAttempts() async {
    await _prefs.remove(_kFailed);
    await _prefs.remove(_kLockedUntil);
  }

  static Uint8List _randomBytes(int n) {
    final random = Random.secure();
    return Uint8List.fromList(List<int>.generate(n, (_) => random.nextInt(256)));
  }

  /// PBKDF2 off the UI isolate, so the PIN pad keeps animating while it runs.
  static Future<Uint8List> _hash(String pin, Uint8List salt, int iterations) {
    return Isolate.run(() => pbkdf2(pin, salt, iterations));
  }

  static Uint8List pbkdf2(String pin, Uint8List salt, int iterations) {
    final derivator = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64))
      ..init(pc.Pbkdf2Parameters(salt, iterations, 32));
    return derivator.process(Uint8List.fromList(utf8.encode(pin)));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
