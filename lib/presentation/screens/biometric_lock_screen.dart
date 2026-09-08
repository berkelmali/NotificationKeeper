import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

/// Merged from base.apk (com.example.fluter)'s BiometricVaultScreen.
///
/// Shown before [MainScreen] when the user has enabled "Biometric Lock" in
/// Settings. `local_auth`'s authenticate() call falls back to the device's
/// PIN/pattern/password automatically when no biometric is enrolled or the
/// hardware isn't available, so no separate custom PIN UI is needed.
///
/// The vault also re-locks itself: unlocking used to last for the whole app
/// process, so anything that reached the app switcher - or simply reopening the
/// app hours later without the OS having killed it - showed the archive with no
/// authentication at all. A vault that only asks once per boot is not a vault.
/// Leaving the app for longer than [relockAfter] now clears the unlock.
class BiometricLockScreen extends StatefulWidget {
  final Widget child;

  const BiometricLockScreen({super.key, required this.child});

  /// How long the app may sit in the background before the vault re-locks.
  ///
  /// Not zero: glancing at another app to type a captured code, or picking a
  /// backup file, briefly backgrounds this one, and demanding a fingerprint on
  /// every return would make the app hostile to its own core use case. Half a
  /// minute is the usual compromise for password managers.
  static const Duration relockAfter = Duration(seconds: 30);

  /// Whether an app that went to the background at [since] should be asked to
  /// authenticate again now. Split out from the lifecycle handler so the timing
  /// rule can be tested without standing up a fake biometric platform channel.
  ///
  /// A null [since] means the app was never backgrounded while unlocked - which
  /// is also the case while the system biometric sheet is on screen, since that
  /// only ever happens while we are still locked.
  static bool shouldRelock(DateTime? since, DateTime now) {
    if (since == null) return false;
    return now.difference(since) >= relockAfter;
  }

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();

  // 'idle' | 'authenticating' | 'unlocked' | 'denied' | 'error'
  String _state = 'idle';
  String _errorMsg = '';

  /// When the app was last backgrounded *while already unlocked*.
  DateTime? _backgroundedAt;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.88, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Prompt automatically on first show, like base.apk did.
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Only ever arm the timer while the vault is actually open. This is what
    // keeps the system biometric prompt from re-locking us: that prompt takes
    // the app out of the foreground too, but it only ever appears while we are
    // still locked, so there is no unlock for it to clobber.
    if (_state != 'unlocked') return;

    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _backgroundedAt ??= DateTime.now();
        break;
      case AppLifecycleState.resumed:
        final since = _backgroundedAt;
        _backgroundedAt = null;
        if (BiometricLockScreen.shouldRelock(since, DateTime.now())) {
          setState(() {
            _state = 'idle';
            _errorMsg = '';
          });
          WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
        }
        break;
      case AppLifecycleState.inactive:
        // Transient (notification shade pulled down, incoming call banner, the
        // biometric sheet itself). Deliberately not treated as backgrounded.
        break;
    }
  }

  Future<void> _authenticate() async {
    if (_state == 'authenticating' || _state == 'unlocked') return;
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _state = 'authenticating';
      _errorMsg = '';
    });

    try {
      final bool result = await _auth
          .authenticate(
            localizedReason: l10n.biometricAuthReason,
          )
          .timeout(const Duration(seconds: 30), onTimeout: () => false);

      if (!mounted) return;

      if (result) {
        setState(() => _state = 'unlocked');
      } else {
        setState(() {
          _state = 'denied';
          _errorMsg = l10n.biometricAuthCancelled;
        });
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'NotEnrolled':
          msg = l10n.biometricNotEnrolled;
          break;
        case 'LockedOut':
        case 'PermanentlyLockedOut':
          msg = l10n.biometricLockedOut;
          break;
        case 'NotAvailable':
          msg = l10n.biometricNotAvailable;
          break;
        default:
          msg = e.message ?? 'Authentication error (${e.code})';
      }
      setState(() {
        _state = 'error';
        _errorMsg = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_state == 'unlocked') {
      return widget.child;
    }

    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isError = _state == 'denied' || _state == 'error';
    final Color accentColor = isError ? AppColors.error : AppColors.primaryStart;
    final Color background = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, _) {
                    return Transform.scale(
                      scale: _state == 'authenticating' ? _pulseAnim.value : 1.0,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withValues(alpha: 0.08),
                          border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 2),
                        ),
                        child: Icon(
                          isError ? Icons.lock_outline : Icons.fingerprint,
                          size: 68,
                          color: accentColor,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
                Text(
                  l10n.lockedTitle,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 5.0,
                    color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 14),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _state == 'authenticating'
                        ? l10n.awaitingVerification
                        : isError
                            ? _errorMsg
                            : l10n.archiveProtectedMessage,
                    key: ValueKey(_state),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.7,
                      letterSpacing: 0.5,
                      color: _state == 'authenticating'
                          ? accentColor
                          : isError
                              ? AppColors.error
                              : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                if (_state == 'authenticating')
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    strokeWidth: 2.5,
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isError ? Colors.transparent : AppColors.primaryStart,
                        foregroundColor: isError ? AppColors.error : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isError ? BorderSide(color: AppColors.error) : BorderSide.none,
                        ),
                        elevation: 0,
                      ),
                      onPressed: _authenticate,
                      icon: Icon(!isError ? Icons.fingerprint : Icons.refresh, size: 22),
                      label: Text(
                        isError ? l10n.retryButton : l10n.tapToUnlock,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
