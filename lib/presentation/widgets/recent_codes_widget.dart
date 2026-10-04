import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/models/notification_model.dart';
import '../theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/app_registry.dart';

/// Merged from base.apk (com.example.fluter)'s RecentCodesWidget.
///
/// Surfaces recently captured verification/OTP codes (detected natively via
/// regex in NotificationListener.kt) in a horizontally scrolling row, so the
/// user doesn't have to hunt through the archive to find a code they just
/// received. Tapping a chip copies the code to the clipboard; the code then
/// auto-masks itself after a few seconds so it isn't left glowing on screen
/// (new feature - security refinement on top of base.apk's original widget).
class RecentCodesWidget extends StatelessWidget {
  final List<NotificationModel> notifications;

  const RecentCodesWidget({super.key, required this.notifications});

  @override
  Widget build(BuildContext context) {
    final otpNotifications = notifications
        .where((n) => n.isOtp && (n.extractedCode?.isNotEmpty ?? false))
        .toList();

    if (otpNotifications.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8),
      height: 90,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.vpn_key_rounded, color: AppColors.primaryStart, size: 16),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)!.recentCodesTitle,
                style: TextStyle(
                  color: AppColors.primaryStart,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              Text(
                AppLocalizations.of(context)!.tapToCopy,
                style: TextStyle(color: AppColors.textTertiary, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: otpNotifications.length,
              itemBuilder: (context, index) {
                final notif = otpNotifications[index];
                return _CodeChip(
                  key: ValueKey('${notif.id}_${notif.extractedCode}'),
                  code: notif.extractedCode!,
                  appLabel: context.appLabel(notif.packageName),
                  isDark: isDark,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeChip extends StatefulWidget {
  final String code;
  final String appLabel;
  final bool isDark;

  const _CodeChip({super.key, required this.code, required this.appLabel, required this.isDark});

  @override
  State<_CodeChip> createState() => _CodeChipState();
}

class _CodeChipState extends State<_CodeChip> {
  bool _masked = false;

  String get _displayCode {
    if (!_masked) return widget.code;
    return '•' * widget.code.length;
  }

  Future<void> _handleTap() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.codeCopied), duration: const Duration(seconds: 1)),
    );
    // New feature: mask the code a couple seconds after it's been copied,
    // so it doesn't linger legibly on screen once it's served its purpose.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _masked = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return GestureDetector(
      onTap: _masked ? () => setState(() => _masked = false) : _handleTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : AppColors.cardLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryStart.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.appLabel,
              style: TextStyle(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _displayCode,
              style: TextStyle(
                color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              _masked ? Icons.visibility_off_rounded : Icons.copy_rounded,
              size: 14,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
