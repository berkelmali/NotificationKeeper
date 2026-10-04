import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/notification_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/services/backup_service.dart';
import '../../l10n/generated/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repo = NotificationRepository();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 100),
          children: [
            // ─── Header ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.settingsTitle,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            const SizedBox(height: 24),

            // ─── Theme Section ───
            _SectionHeader(title: l10n.sectionAppearance),
            Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                return GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      _ThemeOption(
                        title: l10n.themeDark,
                        icon: Icons.dark_mode_rounded,
                        isSelected: settings.themeMode == ThemeMode.dark,
                        onTap: () => settings.setThemeMode(ThemeMode.dark),
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.cardBorder
                            : AppColors.cardBorderLight,
                        indent: 56,
                      ),
                      _ThemeOption(
                        title: l10n.themeLight,
                        icon: Icons.light_mode_rounded,
                        isSelected: settings.themeMode == ThemeMode.light,
                        onTap: () => settings.setThemeMode(ThemeMode.light),
                      ),
                      Divider(
                        height: 1,
                        color: isDark
                            ? AppColors.cardBorder
                            : AppColors.cardBorderLight,
                        indent: 56,
                      ),
                      _ThemeOption(
                        title: l10n.themeSystem,
                        icon: Icons.settings_brightness_rounded,
                        isSelected: settings.themeMode == ThemeMode.system,
                        onTap: () => settings.setThemeMode(ThemeMode.system),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ─── New feature: Language ───
            _SectionHeader(title: l10n.sectionLanguage),
            Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                return GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      _ThemeOption(
                        title: l10n.themeSystem,
                        icon: Icons.translate_rounded,
                        isSelected: settings.appLocale == null,
                        onTap: () => settings.setAppLocale(null),
                      ),
                      Divider(
                        height: 1,
                        color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight,
                        indent: 56,
                      ),
                      _ThemeOption(
                        title: 'English',
                        icon: Icons.language_rounded,
                        isSelected: settings.appLocale?.languageCode == 'en',
                        onTap: () => settings.setAppLocale(const Locale('en')),
                      ),
                      Divider(
                        height: 1,
                        color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight,
                        indent: 56,
                      ),
                      _ThemeOption(
                        title: 'Türkçe',
                        icon: Icons.language_rounded,
                        isSelected: settings.appLocale?.languageCode == 'tr',
                        onTap: () => settings.setAppLocale(const Locale('tr')),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ─── Security (merged from base.apk: Biometric Vault lock) ───
            _SectionHeader(title: l10n.sectionSecurity),
            Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                return GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: SwitchListTile(
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: settings.biometricLockEnabled
                            ? AppColors.primaryStart.withValues(alpha: 0.15)
                            : (isDark ? AppColors.cardDark : AppColors.cardLight),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.fingerprint_rounded,
                        color: settings.biometricLockEnabled
                            ? AppColors.primaryStart
                            : AppColors.textTertiary,
                        size: 20,
                      ),
                    ),
                    title: Text(l10n.biometricLockTitle),
                    subtitle: Text(
                      settings.biometricLockEnabled
                          ? l10n.biometricLockSubtitleOn
                          : l10n.biometricLockSubtitleOff,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    value: settings.biometricLockEnabled,
                    onChanged: (value) => settings.setBiometricLockEnabled(value),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // ─── New feature B: Code Shredder (ephemeral verification codes) ───
            Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                final isOn = settings.otpShredMinutes > 0;
                return GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isOn
                                ? AppColors.error.withValues(alpha: 0.15)
                                : (isDark ? AppColors.cardDark : AppColors.cardLight),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.local_fire_department_rounded,
                            color: isOn ? AppColors.error : AppColors.textTertiary,
                            size: 20,
                          ),
                        ),
                        title: Text(l10n.codeShredTitle),
                        subtitle: Text(
                          isOn
                              ? _shredWindowLabel(l10n, settings.otpShredMinutes)
                              : l10n.codeShredSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => _showShredWindowDialog(context, settings, repo),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Text(
                          l10n.codeShredExplainer,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppColors.textTertiary,
                                height: 1.5,
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ─── Feature 5 (Clone from Notisave): Quiet Hours ───
            _SectionHeader(title: l10n.sectionQuietHours),
            Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                return GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: [
                      SwitchListTile(
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: settings.quietHoursEnabled
                                ? AppColors.warning.withValues(alpha: 0.15)
                                : (isDark
                                    ? AppColors.cardDark
                                    : AppColors.cardLight),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.do_not_disturb_on_rounded,
                            color: settings.quietHoursEnabled
                                ? AppColors.warning
                                : AppColors.textTertiary,
                            size: 20,
                          ),
                        ),
                        title: Text(l10n.enableQuietHours),
                        subtitle: Text(
                          settings.quietHoursEnabled
                              ? l10n.quietHoursActiveRange(
                                  _formatTime(settings.quietHoursStart),
                                  _formatTime(settings.quietHoursEnd),
                                )
                              : l10n.quietHoursSubtitle,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        value: settings.quietHoursEnabled,
                        // BUG FIX: the toggle only ever wrote to Flutter's own
                        // SharedPreferences - the native listener reads a
                        // different store and was only ever updated by the two
                        // time pickers below. Turning Quiet Hours on (or off)
                        // without also touching a time therefore did nothing at
                        // all natively. Push the whole window here too.
                        onChanged: (value) {
                          settings.setQuietHoursEnabled(value);
                          repo.setQuietHours(
                            value,
                            settings.quietHoursStart.hour,
                            settings.quietHoursStart.minute,
                            settings.quietHoursEnd.hour,
                            settings.quietHoursEnd.minute,
                          );
                        },
                      ),
                      if (settings.quietHoursEnabled) ...[
                        Divider(
                          height: 1,
                          color: isDark
                              ? AppColors.cardBorder
                              : AppColors.cardBorderLight,
                          indent: 56,
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.bedtime_rounded,
                            color: AppColors.primaryStart,
                          ),
                          title: Text(l10n.startTime),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryStart.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _formatTime(settings.quietHoursStart),
                              style: const TextStyle(
                                color: AppColors.primaryStart,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: settings.quietHoursStart,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    timePickerTheme: TimePickerThemeData(
                                      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (time != null) {
                              settings.setQuietHoursStart(time);
                              repo.setQuietHours(
                                settings.quietHoursEnabled,
                                time.hour,
                                time.minute,
                                settings.quietHoursEnd.hour,
                                settings.quietHoursEnd.minute,
                              );
                            }
                          },
                        ),
                        Divider(
                          height: 1,
                          color: isDark
                              ? AppColors.cardBorder
                              : AppColors.cardBorderLight,
                          indent: 56,
                        ),
                        ListTile(
                          leading: Icon(
                            Icons.wb_sunny_rounded,
                            color: AppColors.accent,
                          ),
                          title: Text(l10n.endTime),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _formatTime(settings.quietHoursEnd),
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: settings.quietHoursEnd,
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    timePickerTheme: TimePickerThemeData(
                                      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (time != null) {
                              settings.setQuietHoursEnd(time);
                              repo.setQuietHours(
                                settings.quietHoursEnabled,
                                settings.quietHoursStart.hour,
                                settings.quietHoursStart.minute,
                                time.hour,
                                time.minute,
                              );
                            }
                          },
                        ),
                        // Status indicator
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: settings.isQuietHoursActive
                                  ? AppColors.warning.withValues(alpha: 0.1)
                                  : AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: settings.isQuietHoursActive
                                    ? AppColors.warning.withValues(alpha: 0.3)
                                    : AppColors.success.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  settings.isQuietHoursActive
                                      ? Icons.do_not_disturb_on_rounded
                                      : Icons.notifications_active_rounded,
                                  size: 18,
                                  color: settings.isQuietHoursActive
                                      ? AppColors.warning
                                      : AppColors.success,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  settings.isQuietHoursActive
                                      ? l10n.quietHoursActiveNote
                                      : l10n.captureActiveNote,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: settings.isQuietHoursActive
                                        ? AppColors.warning
                                        : AppColors.success,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ─── Keyword Radar (merged from base.apk) ───
            _SectionHeader(title: l10n.sectionKeywordRadar),
            _KeywordRadarCard(isDark: isDark, repo: repo),
            const SizedBox(height: 12),

            // New feature: instant local alerts for captured codes/priority matches
            Consumer<SettingsProvider>(
              builder: (context, settings, _) {
                return GlassCard(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: SwitchListTile(
                    secondary: Icon(Icons.notifications_active_outlined,
                        color: settings.instantAlertsEnabled ? AppColors.primaryStart : AppColors.textTertiary),
                    title: Text(l10n.instantAlertsTitle),
                    subtitle: Text(
                      l10n.instantAlertsSubtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    value: settings.instantAlertsEnabled,
                    onChanged: (value) {
                      settings.setInstantAlertsEnabled(value);
                      repo.setInstantAlertsEnabled(value);
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // ─── Photo vault ───
            _SectionHeader(title: l10n.sectionPhotos),
            _PhotoVaultCard(repo: repo),
            const SizedBox(height: 24),

            // ─── Data Management ───
            _SectionHeader(title: l10n.sectionDataManagement),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.cleaning_services_rounded,
                    title: l10n.clearOldNotificationsTitle,
                    subtitle: l10n.clearOldNotificationsSubtitle,
                    onTap: () => _showCleanupDialog(context, repo),
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.cardBorder
                        : AppColors.cardBorderLight,
                    indent: 56,
                  ),
                  // Merged from base.apk (BurnerWorker): automatic recurring cleanup
                  Consumer<SettingsProvider>(
                    builder: (context, settings, _) {
                      return _SettingsTile(
                        icon: Icons.auto_delete_outlined,
                        title: l10n.automaticCleanupTitle,
                        subtitle: settings.retentionDays == 0
                            ? l10n.automaticCleanupOff
                            : l10n.automaticCleanupOn(settings.retentionDays),
                        onTap: () => _showRetentionDialog(context, settings, repo),
                      );
                    },
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.cardBorder
                        : AppColors.cardBorderLight,
                    indent: 56,
                  ),
                  _SettingsTile(
                    icon: Icons.file_download_outlined,
                    title: l10n.exportNotificationsTitle,
                    subtitle: l10n.exportNotificationsSubtitle,
                    onTap: () => _showExportDialog(context, repo),
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.cardBorder
                        : AppColors.cardBorderLight,
                    indent: 56,
                  ),
                  // Feature 1 (Unique): Clear search history
                  _SettingsTile(
                    icon: Icons.manage_search_rounded,
                    title: l10n.clearSearchHistoryTitle,
                    subtitle: l10n.clearSearchHistorySubtitle,
                    onTap: () {
                      Provider.of<SettingsProvider>(context, listen: false)
                          .clearSearchHistory();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.searchHistoryCleared)),
                      );
                    },
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? AppColors.cardBorder
                        : AppColors.cardBorderLight,
                    indent: 56,
                  ),
                  _SettingsTile(
                    icon: Icons.delete_forever_rounded,
                    title: l10n.deleteAllNotificationsTitle,
                    subtitle: l10n.deleteAllNotificationsSubtitle,
                    iconColor: AppColors.error,
                    onTap: () => _showDeleteAllDialog(context, repo),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── New feature: Backup & Restore ───
            _SectionHeader(title: l10n.sectionBackupRestore),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.backup_outlined,
                    title: l10n.backupNowTitle,
                    subtitle: l10n.backupNowSubtitle,
                    onTap: () => _showBackupDialog(context, repo),
                  ),
                  Divider(
                    height: 1,
                    color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight,
                    indent: 56,
                  ),
                  _SettingsTile(
                    icon: Icons.restore_outlined,
                    title: l10n.restoreFromBackupTitle,
                    subtitle: l10n.restoreFromBackupSubtitle,
                    onTap: () => _showRestoreDialog(context, repo),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Service ───
            _SectionHeader(title: l10n.sectionService),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: _SettingsTile(
                icon: Icons.notifications_active_rounded,
                title: l10n.notificationAccessTitle,
                subtitle: l10n.notificationAccessSubtitle,
                onTap: () => repo.openNotificationSettings(),
              ),
            ),
            const SizedBox(height: 24),

            // ─── About ───
            _SectionHeader(title: l10n.sectionAbout),
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.notifications_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.appTitle,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.versionLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Never miss a notification again. Keep track of all your notifications in one beautiful archive.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  // Feature badges
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _FeatureBadge(label: l10n.featureHeatmap, icon: Icons.grid_view_rounded),
                      _FeatureBadge(label: l10n.featureTags, icon: Icons.label_rounded),
                      _FeatureBadge(label: l10n.featureQuietHours, icon: Icons.do_not_disturb_on_rounded),
                      _FeatureBadge(label: l10n.featureCopy, icon: Icons.copy_rounded),
                      _FeatureBadge(label: l10n.featureSearchHistory, icon: Icons.history_rounded),
                      _FeatureBadge(label: l10n.featureAppDetails, icon: Icons.app_registration_rounded),
                      _FeatureBadge(label: l10n.featureBiometricLock, icon: Icons.fingerprint_rounded),
                      _FeatureBadge(label: l10n.featureKeywordRadar, icon: Icons.radar_rounded),
                      _FeatureBadge(label: l10n.featureAutoCleanup, icon: Icons.auto_delete_outlined),
                      _FeatureBadge(label: l10n.featureCodeDetection, icon: Icons.vpn_key_rounded),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showCleanupDialog(BuildContext context, NotificationRepository repo) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.clearOldNotificationsTitle),
        content: Text(l10n.chooseCleanupPeriod),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteOlderThan(context, repo, 7);
            },
            child: Text(l10n.keep7Days),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteOlderThan(context, repo, 30);
            },
            child: Text(l10n.keep30Days),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteOlderThan(context, repo, 90);
            },
            child: Text(l10n.keep90Days),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancelAction),
          ),
        ],
      ),
    );
  }

  void _deleteOlderThan(
      BuildContext context, NotificationRepository repo, int days) async {
    final l10n = AppLocalizations.of(context)!;
    final success = await repo.deleteOlderThan(days);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? l10n.notificationsDeletedCount(days)
                : l10n.failedToDeleteNotifications,
          ),
        ),
      );
    }
  }

  void _showDeleteAllDialog(
      BuildContext context, NotificationRepository repo) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteAllQuestion),
        content: Text(l10n.deleteAllConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancelAction),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await repo.deleteAllNotifications();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? l10n.allNotificationsDeleted
                          : l10n.failedToDelete,
                    ),
                  ),
                );
              }
            },
            child: Text(
              l10n.deleteAllAction,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  /// New feature: real backup with optional passphrase encryption.
  void _showBackupDialog(BuildContext context, NotificationRepository repo) {
    final l10n = AppLocalizations.of(context)!;
    final passphraseController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.backupNowTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.backupPassphraseHint),
            const SizedBox(height: 12),
            TextField(
              controller: passphraseController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.passphraseOptionalLabel,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancelAction),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final passphrase = passphraseController.text.trim();
              final backupService = BackupService(repo);
              try {
                final path = await backupService.createBackup(
                  passphrase: passphrase.isEmpty ? null : passphrase,
                );
                if (context.mounted) {
                  await Share.shareXFiles([XFile(path)],
                      subject: l10n.appTitle);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.backupFailed(e.toString()))),
                  );
                }
              }
            },
            child: Text(l10n.createBackupAction),
          ),
        ],
      ),
    );
  }

  /// New feature: restore from a previously created backup file.
  void _showRestoreDialog(BuildContext context, NotificationRepository repo) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      dialogTitle: l10n.selectBackupFileTitle,
    );
    if (result == null || result.files.single.path == null) return;
    final filePath = result.files.single.path!;

    if (!context.mounted) return;
    final passphraseController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.restoreFromBackupTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.restoreExplanation),
            const SizedBox(height: 12),
            TextField(
              controller: passphraseController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.passphraseIfEncryptedLabel,
                isDense: true,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancelAction),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final passphrase = passphraseController.text.trim();
              final backupService = BackupService(repo);
              final restoreResult = await backupService.restoreBackup(
                filePath: filePath,
                passphrase: passphrase.isEmpty ? null : passphrase,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      restoreResult.isSuccess
                          ? l10n.restoredCount(restoreResult.restoredCount)
                          : restoreResult.errorMessage ?? l10n.restoreFailedGeneric,
                    ),
                  ),
                );
              }
            },
            child: Text(l10n.restoreAction),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context, NotificationRepository repo) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.exportNotificationsTitle),
        content: Text(l10n.chooseExportFormat),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _exportNotifications(context, repo, 'json');
            },
            child: Text(l10n.exportFormatJson),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _exportNotifications(context, repo, 'csv');
            },
            child: Text(l10n.exportFormatCsv),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancelAction),
          ),
        ],
      ),
    );
  }

  void _exportNotifications(
      BuildContext context, NotificationRepository repo, String format) async {
    final l10n = AppLocalizations.of(context)!;
    final path = await repo.exportNotifications(format: format);
    if (path != null && context.mounted) {
      await Share.shareXFiles(
        [XFile(path)],
        subject: l10n.appTitle,
      );
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.failedToExportNotifications)),
      );
    }
  }

  /// Merged from base.apk (com.example.fluter): "Data Hygiene" / BurnerWorker.
  /// Sets how many days of history the automatic background cleanup keeps;
  /// 0 disables it entirely (keep forever).
  void _showRetentionDialog(
      BuildContext context, SettingsProvider settings, NotificationRepository repo) {
    final l10n = AppLocalizations.of(context)!;
    Future<void> apply(int days) async {
      Navigator.pop(context);
      await settings.setRetentionDays(days);
      await repo.setRetentionDays(days);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              days == 0
                  ? l10n.automaticCleanupOffToast
                  : l10n.automaticCleanupOnToast(days),
            ),
          ),
        );
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.automaticCleanupTitle),
        content: Text(l10n.automaticCleanupExplanation),
        actions: [
          TextButton(onPressed: () => apply(3), child: Text(l10n.days3Short)),
          TextButton(onPressed: () => apply(7), child: Text(l10n.days7Short)),
          TextButton(onPressed: () => apply(30), child: Text(l10n.days30Short)),
          TextButton(onPressed: () => apply(90), child: Text(l10n.days90Short)),
          TextButton(onPressed: () => apply(0), child: Text(l10n.cleanupOff)),
        ],
      ),
    );
  }

  /// New feature B: Code Shredder. Human label for the currently selected window.
  String _shredWindowLabel(AppLocalizations l10n, int minutes) {
    if (minutes <= 0) return l10n.codeShredOff;
    if (minutes >= 1440) return l10n.codeShredDay;
    if (minutes >= 60) return l10n.codeShredHour;
    return l10n.codeShredMinutes(minutes);
  }

  /// New feature B: how long a captured verification code may survive before
  /// its digits are destroyed. 0 keeps codes forever (the old behavior).
  void _showShredWindowDialog(
      BuildContext context, SettingsProvider settings, NotificationRepository repo) {
    final l10n = AppLocalizations.of(context)!;

    Future<void> apply(int minutes) async {
      Navigator.pop(context);
      await settings.setOtpShredMinutes(minutes);
      // The native side wipes anything that is already past the new window and
      // reports how much it destroyed, so shortening the window has a visible,
      // immediate effect rather than waiting for the next worker tick.
      final shredded = await repo.setOtpShredMinutes(minutes);
      if (context.mounted && shredded > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.codeShredDone(shredded))),
        );
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? AppColors.surfaceDark
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.codeShredTitle),
        content: Text(l10n.codeShredExplainer),
        actions: [
          TextButton(onPressed: () => apply(5), child: Text(l10n.codeShredMinutes(5))),
          TextButton(onPressed: () => apply(15), child: Text(l10n.codeShredMinutes(15))),
          TextButton(onPressed: () => apply(60), child: Text(l10n.codeShredHour)),
          TextButton(onPressed: () => apply(1440), child: Text(l10n.codeShredDay)),
          TextButton(onPressed: () => apply(0), child: Text(l10n.codeShredOff)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryStart,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primaryStart : AppColors.textTertiary,
      ),
      title: Text(title),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded,
              color: AppColors.primaryStart, size: 22)
          : null,
      onTap: onTap,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? AppColors.primaryStart,
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: AppColors.textTertiary,
      ),
      onTap: onTap,
    );
  }
}

/// Merged from base.apk (com.example.fluter): "Keyword Radar" settings UI.
/// Lets the user maintain a list of case-insensitive words; any captured
/// notification whose title/content matches one is flagged as priority
/// (isPriorityFlagged) by the native listener.
class _KeywordRadarCard extends StatefulWidget {
  final bool isDark;
  final NotificationRepository repo;

  const _KeywordRadarCard({required this.isDark, required this.repo});

  @override
  State<_KeywordRadarCard> createState() => _KeywordRadarCardState();
}

class _KeywordRadarCardState extends State<_KeywordRadarCard> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add(SettingsProvider settings) {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    settings.addPriorityKeyword(value);
    widget.repo.updateKeywords([...settings.priorityKeywords, value]);
    _controller.clear();
  }

  void _remove(SettingsProvider settings, String keyword) {
    settings.removePriorityKeyword(keyword);
    widget.repo.updateKeywords(
      settings.priorityKeywords.where((k) => k != keyword).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.keywordRadarExplanation,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: l10n.keywordHint,
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onSubmitted: (_) => _add(settings),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryStart,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _add(settings),
                    child: Text(l10n.addAction),
                  ),
                ],
              ),
              if (settings.priorityKeywords.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: settings.priorityKeywords
                      .map((kb) => Chip(
                            label: Text(kb),
                            onDeleted: () => _remove(settings, kb),
                            backgroundColor: widget.isDark ? AppColors.cardDark : AppColors.cardLight,
                            side: BorderSide(
                              color: widget.isDark ? AppColors.cardBorder : AppColors.cardBorderLight,
                            ),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _FeatureBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _FeatureBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primaryStart.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryStart.withValues(alpha: 0.2),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.primaryStart),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryStart,
            ),
          ),
        ],
      ),
    );
  }
}

/// Photo vault settings: the on/off switch, how much the kept photos weigh,
/// and a way to delete them all without touching the notifications.
class _PhotoVaultCard extends StatefulWidget {
  final NotificationRepository repo;

  const _PhotoVaultCard({required this.repo});

  @override
  State<_PhotoVaultCard> createState() => _PhotoVaultCardState();
}

class _PhotoVaultCardState extends State<_PhotoVaultCard> {
  PhotoStorageStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await widget.repo.getPhotoStorageStats();
    if (mounted) setState(() => _stats = stats);
  }

  Future<void> _confirmDeleteAll(AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAllPhotosTitle),
        content: Text(l10n.deleteAllPhotosBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelAction),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: Text(l10n.deleteAction),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await widget.repo.deleteAllPhotos();
    if (!mounted) return;
    // The archive still holds the old image paths in memory; reload it.
    await Provider.of<NotificationProvider>(context, listen: false).fetchNotifications();
    await _loadStats();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.photosDeleted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = _stats;

    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: [
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: settings.capturePhotos
                        ? AppColors.accent.withValues(alpha: 0.15)
                        : (isDark ? AppColors.cardDark : AppColors.cardLight),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.photo_library_rounded,
                    color: settings.capturePhotos ? AppColors.accent : AppColors.textTertiary,
                    size: 20,
                  ),
                ),
                title: Text(l10n.capturePhotosTitle),
                subtitle: Text(
                  l10n.capturePhotosSubtitle,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                value: settings.capturePhotos,
                onChanged: (value) {
                  settings.setCapturePhotos(value);
                  widget.repo.setCapturePhotos(value);
                },
              ),
              if (stats != null && stats.count > 0)
                _SettingsTile(
                  icon: Icons.delete_sweep_rounded,
                  iconColor: AppColors.error,
                  title: l10n.deleteAllPhotosTitle,
                  subtitle: l10n.photoStorageUsage(stats.count, stats.formattedSize),
                  onTap: () => _confirmDeleteAll(l10n),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Text(
                  l10n.photoPrivacyNote,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textTertiary,
                        height: 1.5,
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
