import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../data/services/vault_service.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../providers/vault_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/pin_pad.dart';
import 'vault_setup_screen.dart';

/// The vault's lock, laid over the whole app while the vault is on.
///
/// It sits in [MaterialApp.builder], above the app's navigator, so it covers
/// every screen, sheet and dialog that is open - a photo left open in the
/// viewer stays hidden too. The navigator stays alive underneath, so unlocking
/// returns to exactly where you were.
///
/// With a vault PIN: a PIN pad, plus fingerprint unlock when it is switched
/// on. Without one (installs from before the PIN existed, still on the old
/// biometric-only lock) it unlocks through Android's own prompt and then
/// offers, once, to add a PIN.
///
/// The app locks when it starts and again after [relockAfter] in the
/// background. Switching the vault on does not lock you out of the screen you
/// are on.
class VaultLockScreen extends StatefulWidget {
  /// The app's navigator, as handed to [MaterialApp.builder].
  final Widget child;

  /// Where screens opened from the lock go (a new PIN after "forgot PIN"),
  /// once the lock is out of the way.
  final GlobalKey<NavigatorState> navigatorKey;

  /// How long the app may sit in the background before the vault re-locks.
  final Duration relockAfter;

  const VaultLockScreen({
    super.key,
    required this.child,
    required this.navigatorKey,
    this.relockAfter = defaultRelockAfter,
  });

  /// Not zero: glancing at another app to type a captured code, or picking a
  /// backup file, briefly backgrounds this one, and a PIN on every return
  /// would make the app hostile to its own core use case.
  static const Duration defaultRelockAfter = Duration(seconds: 30);

  /// The allowance for a trip to Android's fingerprint settings that the app
  /// itself started: adding a finger takes longer than [defaultRelockAfter], and
  /// coming back to a PIN pad halfway through setting up fingerprint unlock
  /// would be absurd.
  static const Duration enrollmentTripAllowance = Duration(minutes: 10);

  /// Whether an app that went to the background at [since] must unlock again
  /// now. Split out so the timing rule can be tested on its own. A null [since]
  /// means it was never backgrounded while unlocked.
  static bool shouldRelock(DateTime? since, DateTime now, {Duration after = defaultRelockAfter}) {
    if (since == null) return false;
    return now.difference(since) >= after;
  }

  @override
  State<VaultLockScreen> createState() => _VaultLockScreenState();
}

class _VaultLockScreenState extends State<VaultLockScreen> with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();

  /// The PIN pad (or the old prompt) is showing.
  late bool _locked;

  DateTime? _backgroundedAt;

  /// Left the app while the lock was showing; ask for the fingerprint again
  /// on the way back, since leaving cancels Android's prompt.
  bool _leftWhileLocked = false;

  bool _busy = false;
  String? _error;
  int _errorSignal = 0;

  /// Why "forgot PIN" could not go ahead. Shown apart from the PIN error line,
  /// which a running lockout countdown occupies.
  String? _forgotProblem;
  Timer? _lockoutTicker;
  Duration? _lockoutLeft;

  /// The fingerprints on the phone changed since fingerprint unlock was set up:
  /// fingerprints are refused until the PIN is entered.
  bool _biometricSuspended = false;
  bool _offeredUpgrade = false;
  bool? _recentsHidden;

  bool get _vaultOn {
    return context.read<VaultProvider>().hasPin || context.read<SettingsProvider>().biometricLockEnabled;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _locked = _vaultOn;
    if (_locked) WidgetsBinding.instance.addPostFrameCallback((_) => _onLocked());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockoutTicker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!_vaultOn) return;

    if (_locked) {
      // Android's own prompts briefly background the app; only a real trip
      // away (and no prompt in flight) asks for the fingerprint again.
      if (state == AppLifecycleState.paused) _leftWhileLocked = true;
      if (state == AppLifecycleState.resumed && _leftWhileLocked) {
        _leftWhileLocked = false;
        _promptBiometricIfReady();
      }
      return;
    }

    // No frames are drawn while the app is hidden, and coming back delivers
    // "resumed" before the first new one: the lock is in place before
    // anything is drawn again.
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _backgroundedAt ??= DateTime.now();
        break;
      case AppLifecycleState.resumed:
        final since = _backgroundedAt;
        _backgroundedAt = null;
        final enrolling = context.read<VaultProvider>().takeEnrollmentTrip();
        final allowance = enrolling ? VaultLockScreen.enrollmentTripAllowance : widget.relockAfter;
        if (VaultLockScreen.shouldRelock(since, DateTime.now(), after: allowance)) _lock();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  void _lock() {
    setState(() {
      _locked = true;
      _error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _onLocked());
  }

  void _unlock() {
    HapticFeedback.mediumImpact();
    _lockoutTicker?.cancel();
    setState(() {
      _locked = false;
      _error = null;
      _forgotProblem = null;
      _lockoutLeft = null;
    });
  }

  Future<void> _onLocked() async {
    if (!mounted) return;
    final vault = context.read<VaultProvider>();
    _startLockoutTicker(vault.lockoutRemaining);
    if (!vault.hasPin) return _legacyUnlock();
    _promptBiometricIfReady();
  }

  void _promptBiometricIfReady() {
    if (!mounted || !_locked || _busy) return;
    final vault = context.read<VaultProvider>();
    // Fingerprints stay usable through a PIN lockout: only the owner's own
    // fingers can pass, so there is nothing to slow down.
    if (vault.biometricEnabled && !_biometricSuspended) _biometricUnlock();
  }

  Future<void> _biometricUnlock() async {
    if (_busy || !_locked) return;
    final l10n = AppLocalizations.of(context)!;
    final vault = context.read<VaultProvider>();
    setState(() => _busy = true);
    final result = await vault.unlockWithBiometrics(
      title: l10n.vaultBiometricReason,
      cancelLabel: l10n.vaultUsePin,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (result == BiometricUnlockResult.invalidated) _biometricSuspended = true;
      if (result == BiometricUnlockResult.lockout) _error = l10n.vaultFingerprintLockedOut;
    });
    if (result == BiometricUnlockResult.ok) _unlock();
  }

  Future<void> _legacyUnlock() async {
    if (_busy || !_locked) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _error = null;
    });
    var ok = false;
    try {
      ok = await _auth.authenticate(localizedReason: l10n.biometricAuthReason);
    } on LocalAuthException catch (e) {
      if (mounted) setState(() => _error = _authProblem(l10n, e.code));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!ok || !mounted) return;
    _unlock();
    WidgetsBinding.instance.addPostFrameCallback((_) => _offerPinUpgrade());
  }

  Future<void> _submitPin(String pin) async {
    final l10n = AppLocalizations.of(context)!;
    final vault = context.read<VaultProvider>();
    setState(() {
      _busy = true;
      _forgotProblem = null;
    });
    final check = await vault.verifyPin(pin);
    if (!mounted) return;

    switch (check.result) {
      case PinCheckResult.ok:
        if (_biometricSuspended && vault.biometricEnabled) {
          // The PIN proves it is the owner: let the fingerprints that are on
          // the phone now unlock the vault from here on.
          if (!await vault.enableBiometric()) await vault.disableBiometric();
          _biometricSuspended = false;
        }
        if (!mounted) return;
        setState(() => _busy = false);
        _unlock();
        break;
      case PinCheckResult.wrong:
        setState(() {
          _busy = false;
          _error = l10n.vaultWrongPin(check.attemptsLeft);
          _errorSignal++;
        });
        break;
      case PinCheckResult.lockedOut:
        setState(() {
          _busy = false;
          _errorSignal++;
        });
        _startLockoutTicker(check.retryIn);
        break;
    }
  }

  void _startLockoutTicker(Duration? left) {
    _lockoutTicker?.cancel();
    if (left == null) {
      setState(() => _lockoutLeft = null);
      return;
    }
    final until = DateTime.now().add(left);
    void tick() {
      final remaining = until.difference(DateTime.now());
      if (!mounted) return;
      setState(() {
        _lockoutLeft = remaining > Duration.zero ? remaining : null;
        if (_lockoutLeft == null) {
          _error = null;
          _lockoutTicker?.cancel();
        }
      });
    }

    tick();
    _lockoutTicker = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Future<void> _forgotPin() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = true;
      _forgotProblem = null;
    });
    var ok = false;
    try {
      // The phone's screen lock proves ownership. The trade-off - the vault is
      // then only as strong as that screen lock - is stated in Settings.
      ok = await _auth.authenticate(localizedReason: l10n.vaultForgotPinReason);
    } on LocalAuthException catch (e) {
      if (mounted) {
        setState(() => _forgotProblem = e.code == LocalAuthExceptionCode.noCredentialsSet
            ? l10n.vaultForgotNeedsScreenLock
            : _authProblem(l10n, e.code));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!ok || !mounted) return;

    // Let them in, then ask for a new PIN. Backing out keeps the old one, so
    // the vault is never switched off by accident.
    _unlock();
    final navigator = widget.navigatorKey.currentState;
    if (navigator == null) return;
    final changed = await VaultSetupScreen.open(navigator.context, mode: VaultSetupMode.reset);
    if (changed == true && mounted) _snack(l10n.vaultPinChanged);
  }

  Future<void> _offerPinUpgrade() async {
    final navigatorContext = widget.navigatorKey.currentContext;
    if (_offeredUpgrade || !mounted || navigatorContext == null) return;
    _offeredUpgrade = true;
    final l10n = AppLocalizations.of(context)!;
    final add = await showDialog<bool>(
      context: navigatorContext,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.vaultUpgradeTitle),
        content: Text(l10n.vaultUpgradeBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.laterAction)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.vaultContinue)),
        ],
      ),
    );
    if (add != true || !mounted || !navigatorContext.mounted) return;
    final created = await VaultSetupScreen.open(navigatorContext);
    if (created == true && mounted) {
      // The PIN replaces the old biometric-only lock.
      await context.read<SettingsProvider>().setBiometricLockEnabled(false);
      _snack(l10n.vaultSetupDone);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(SnackBar(content: Text(message)));
  }

  /// What to tell the user when Android's own prompt could not confirm them.
  /// Cancelling needs no message: the lock is still there to try again.
  static String? _authProblem(AppLocalizations l10n, LocalAuthExceptionCode code) {
    switch (code) {
      case LocalAuthExceptionCode.userCanceled:
      case LocalAuthExceptionCode.systemCanceled:
      case LocalAuthExceptionCode.timeout:
      case LocalAuthExceptionCode.authInProgress:
      case LocalAuthExceptionCode.userRequestedFallback:
        return null;
      case LocalAuthExceptionCode.noCredentialsSet:
      case LocalAuthExceptionCode.noBiometricsEnrolled:
        return l10n.biometricNotEnrolled;
      case LocalAuthExceptionCode.temporaryLockout:
      case LocalAuthExceptionCode.biometricLockout:
        return l10n.biometricLockedOut;
      case LocalAuthExceptionCode.noBiometricHardware:
      case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
        return l10n.biometricNotAvailable;
      default:
        return l10n.biometricAuthCancelled;
    }
  }

  /// Hides the archive from the app switcher's thumbnail while the vault is on.
  void _syncRecentsPreview(bool vaultOn) {
    if (_recentsHidden == vaultOn) return;
    _recentsHidden = vaultOn;
    context.read<VaultProvider>().setRecentsPreviewHidden(vaultOn);
  }

  @override
  Widget build(BuildContext context) {
    final vault = context.watch<VaultProvider>();
    final legacyLock = context.select<SettingsProvider, bool>((s) => s.biometricLockEnabled);
    final vaultOn = vault.hasPin || legacyLock;
    _syncRecentsPreview(vaultOn);
    // Switched off from Settings while open: nothing left to lock.
    if (!vaultOn) _locked = false;
    final locked = _locked;

    return Stack(
      fit: StackFit.expand,
      children: [
        // The app itself: kept alive while locked, but not painted, not
        // reachable by touch or screen readers, not animating, and without
        // focus - so a keyboard left open cannot type into it.
        Offstage(
          offstage: locked,
          child: TickerMode(
            enabled: !locked,
            child: ExcludeFocus(excluding: locked, child: widget.child),
          ),
        ),
        if (locked)
          _LockLayer(
            child: vault.hasPin
                ? _PinLock(
                    busy: _busy,
                    error: _lockoutLeft != null
                        ? AppLocalizations.of(context)!.vaultLockedOut(formatLockoutTime(_lockoutLeft!))
                        : _error,
                    errorSignal: _errorSignal,
                    lockedOut: _lockoutLeft != null,
                    biometricSuspended: _biometricSuspended && vault.biometricEnabled,
                    forgotProblem: _forgotProblem,
                    onSubmit: _submitPin,
                    onBiometric: vault.biometricEnabled && !_biometricSuspended ? _biometricUnlock : null,
                    onForgot: _forgotPin,
                  )
                : _LegacyLock(busy: _busy, error: _error, onUnlock: _legacyUnlock),
          ),
      ],
    );
  }
}

/// The full-screen backdrop the lock is drawn on. A plain [Material] rather
/// than a Scaffold: it sits outside the app's navigator, and must not pick up
/// the app's snack bars.
class _LockLayer extends StatelessWidget {
  final Widget child;

  const _LockLayer({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _PinLock extends StatelessWidget {
  final bool busy;
  final String? error;
  final int errorSignal;
  final bool lockedOut;
  final bool biometricSuspended;
  final String? forgotProblem;
  final ValueChanged<String> onSubmit;
  final VoidCallback? onBiometric;
  final VoidCallback onForgot;

  const _PinLock({
    required this.busy,
    required this.error,
    required this.errorSignal,
    required this.lockedOut,
    required this.biometricSuspended,
    required this.forgotProblem,
    required this.onSubmit,
    required this.onBiometric,
    required this.onForgot,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.lock_rounded, size: 40, color: AppColors.primaryStart),
        const SizedBox(height: 16),
        if (biometricSuspended) ...[
          _Notice(text: l10n.vaultBiometricChanged),
          const SizedBox(height: 16),
        ],
        if (forgotProblem != null) ...[
          _Notice(icon: Icons.lock_reset_rounded, text: forgotProblem!),
          const SizedBox(height: 16),
        ],
        PinPad(
          title: l10n.vaultLockedTitle,
          subtitle: l10n.vaultEnterPin,
          submitLabel: l10n.vaultUnlock,
          deleteLabel: l10n.deleteDigit,
          biometricLabel: l10n.vaultUseFingerprint,
          enabled: !busy && !lockedOut,
          errorText: error,
          errorSignal: errorSignal,
          onSubmit: onSubmit,
          onBiometric: onBiometric,
          footer: TextButton(
            onPressed: busy ? null : onForgot,
            child: Text(l10n.vaultForgotPin),
          ),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Notice({required this.text, this.icon = Icons.fingerprint_rounded});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.warning, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

/// The pre-PIN lock: one button that raises Android's own prompt.
class _LegacyLock extends StatelessWidget {
  final bool busy;
  final String? error;
  final VoidCallback onUnlock;

  const _LegacyLock({required this.busy, required this.error, required this.onUnlock});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(error == null ? Icons.fingerprint_rounded : Icons.lock_outline_rounded,
            size: 72, color: error == null ? AppColors.primaryStart : AppColors.error),
        const SizedBox(height: 24),
        Text(l10n.lockedTitle,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4)),
        const SizedBox(height: 12),
        Text(
          error ?? l10n.archiveProtectedMessage,
          textAlign: TextAlign.center,
          style: TextStyle(color: error == null ? AppColors.textSecondary : AppColors.error),
        ),
        const SizedBox(height: 32),
        if (busy)
          const CircularProgressIndicator()
        else
          FilledButton.icon(
            onPressed: onUnlock,
            icon: const Icon(Icons.fingerprint_rounded),
            label: Text(l10n.tapToUnlock),
          ),
      ],
    );
  }
}
