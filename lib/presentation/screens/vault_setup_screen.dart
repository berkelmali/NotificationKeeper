import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/vault_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/pin_pad.dart';

enum VaultSetupMode {
  /// Switching the vault on: a PIN, then fingerprint unlock if wanted.
  create,

  /// A new PIN in place of one the user knows. Fingerprint unlock is left
  /// exactly as it was.
  change,

  /// A new PIN after "forgot PIN". Fingerprint unlock is offered again if it
  /// is not on.
  reset,
}

/// Vault registration: choose a PIN, confirm it, then optionally add
/// fingerprint unlock on top. Pops with true once the new PIN is saved.
class VaultSetupScreen extends StatefulWidget {
  final VaultSetupMode mode;

  const VaultSetupScreen({super.key, this.mode = VaultSetupMode.create});

  static Future<bool?> open(BuildContext context, {VaultSetupMode mode = VaultSetupMode.create}) {
    return Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => VaultSetupScreen(mode: mode), fullscreenDialog: true));
  }

  @override
  State<VaultSetupScreen> createState() => _VaultSetupScreenState();
}

enum _Step { create, confirm, biometric }

class _VaultSetupScreenState extends State<VaultSetupScreen> with WidgetsBindingObserver {
  _Step _step = _Step.create;
  String? _firstPin;
  String? _error;
  int _errorSignal = 0;
  bool _busy = false;
  BiometricStatus _status = BiometricStatus.ready;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from Android's fingerprint settings: a finger may be saved now.
    if (state == AppLifecycleState.resumed && _step == _Step.biometric) _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    final status = await context.read<VaultProvider>().biometricStatus();
    if (mounted) setState(() => _status = status);
  }

  Future<void> _onPin(String pin) async {
    final l10n = AppLocalizations.of(context)!;
    if (_step == _Step.create) {
      setState(() {
        _firstPin = pin;
        _error = null;
        _step = _Step.confirm;
      });
      return;
    }
    if (pin != _firstPin) {
      setState(() {
        _error = l10n.vaultPinMismatch;
        _errorSignal++;
        _firstPin = null;
        _step = _Step.create;
      });
      return;
    }

    final vault = context.read<VaultProvider>();
    setState(() => _busy = true);
    await vault.setPin(pin);

    // Fingerprint unlock is only worth offering when it is not on already and
    // the phone has a strong biometric sensor at all.
    final offer = widget.mode != VaultSetupMode.change && !vault.biometricEnabled;
    final status = offer ? await vault.biometricStatus() : BiometricStatus.unsupported;
    if (!mounted) return;
    setState(() => _busy = false);
    if (status == BiometricStatus.unsupported) return _finish();
    setState(() {
      _status = status;
      _step = _Step.biometric;
    });
  }

  Future<void> _enableFingerprint() async {
    setState(() => _busy = true);
    final ok = await context.read<VaultProvider>().enableBiometric();
    if (!mounted) return;
    setState(() {
      _busy = false;
      // The sensor said ready, but the key still could not be made: in
      // practice that means no fingerprint is saved after all.
      if (!ok) _status = BiometricStatus.noneEnrolled;
    });
    if (ok) _finish();
  }

  void _finish() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstTime = widget.mode == VaultSetupMode.create;

    // Once the PIN is saved, backing out of the fingerprint offer is "PIN only".
    return PopScope(
      canPop: _step != _Step.biometric,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) _finish();
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: AnimatedSwitcher(
                duration: MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 260),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(animation),
                    child: child,
                  ),
                ),
                child: _step == _Step.biometric
                    ? _BiometricOffer(
                        key: const ValueKey('biometric'),
                        busy: _busy,
                        status: _status,
                        onYes: _enableFingerprint,
                        onNo: _finish,
                        onAddFingerprint: () => context.read<VaultProvider>().openEnrollment(),
                      )
                    : PinPad(
                        key: ValueKey(_step),
                        title: _step == _Step.confirm
                            ? l10n.vaultConfirmTitle
                            : (firstTime ? l10n.vaultSetupTitle : l10n.vaultNewPinTitle),
                        subtitle: _step == _Step.create ? l10n.vaultSetupSubtitle : null,
                        submitLabel: l10n.vaultContinue,
                        deleteLabel: l10n.deleteDigit,
                        enabled: !_busy,
                        errorText: _error,
                        errorSignal: _errorSignal,
                        onSubmit: _onPin,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BiometricOffer extends StatelessWidget {
  final bool busy;
  final BiometricStatus status;
  final VoidCallback onYes;
  final VoidCallback onNo;
  final VoidCallback onAddFingerprint;

  const _BiometricOffer({
    super.key,
    required this.busy,
    required this.status,
    required this.onYes,
    required this.onNo,
    required this.onAddFingerprint,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final needsFinger = status == BiometricStatus.noneEnrolled;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primaryStart.withValues(alpha: 0.12)),
          child: const Icon(Icons.fingerprint_rounded, size: 56, color: AppColors.primaryStart),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.vaultBiometricOfferTitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(
          l10n.vaultBiometricOfferBody,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
        ),
        if (needsFinger) ...[
          const SizedBox(height: 16),
          Text(
            l10n.vaultNoBiometricEnrolled,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.warning, height: 1.4),
          ),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: busy ? null : (needsFinger ? onAddFingerprint : onYes),
            icon: Icon(needsFinger ? Icons.add_rounded : Icons.fingerprint_rounded),
            label: Text(needsFinger ? l10n.vaultAddFingerprint : l10n.vaultBiometricYes),
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
          ),
        ),
        const SizedBox(height: 8),
        TextButton(onPressed: busy ? null : onNo, child: Text(l10n.vaultBiometricNo)),
      ],
    );
  }
}
