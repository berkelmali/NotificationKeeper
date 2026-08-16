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
class BiometricLockScreen extends StatefulWidget {
  final Widget child;

  const BiometricLockScreen({super.key, required this.child});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _auth = LocalAuthentication();

  // 'idle' | 'authenticating' | 'unlocked' | 'denied' | 'error'
  String _state = 'idle';
  String _errorMsg = '';

  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
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
    _pulseController.dispose();
    super.dispose();
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
                  builder: (_, __) {
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
