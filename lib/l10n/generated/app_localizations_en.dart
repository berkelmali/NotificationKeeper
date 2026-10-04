// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Notification Keeper';

  @override
  String get biometricAuthReason =>
      'Verify your identity to open Notification Keeper';

  @override
  String get biometricAuthCancelled =>
      'Authentication was cancelled or failed.';

  @override
  String get biometricNotEnrolled =>
      'No fingerprint, face, or device PIN enrolled.\nGo to your phone\'s Settings → Security to add one.';

  @override
  String get biometricLockedOut =>
      'Too many failed attempts.\nWait a moment and try again.';

  @override
  String get biometricNotAvailable =>
      'Biometric hardware is not available on this device.';

  @override
  String get lockedTitle => 'LOCKED';

  @override
  String get awaitingVerification => 'AWAITING VERIFICATION...';

  @override
  String get archiveProtectedMessage =>
      'Your notification archive is protected.\nTap the button to unlock.';

  @override
  String get retryButton => 'RETRY';

  @override
  String get tapToUnlock => 'TAP TO UNLOCK';

  @override
  String get recentCodesTitle => 'RECENT CODES';

  @override
  String get tapToCopy => 'Tap to copy';

  @override
  String get codeCopied => 'Code copied';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardSubtitle => 'Your notification overview';

  @override
  String get quietHoursActiveBadge => 'Active';

  @override
  String get quietHoursBadge => 'Quiet';

  @override
  String get statTotal => 'Total';

  @override
  String get statToday => 'Today';

  @override
  String get statThisWeek => 'This Week';

  @override
  String get statUnread => 'Unread';

  @override
  String get statCodesToday => 'Codes Today';

  @override
  String get statPriorityToday => 'Priority Today';

  @override
  String get weeklyTrend => 'Weekly Trend';

  @override
  String get activityHeatmap => 'Activity Heatmap';

  @override
  String get topApps => 'Top Apps';

  @override
  String get recentSectionTitle => 'Recent';

  @override
  String get seeAll => 'See All';

  @override
  String get emptyStateTitle => 'No notifications yet';

  @override
  String get emptyStateSubtitle =>
      'Notifications will appear here once captured';

  @override
  String get archiveTitle => 'Archive';

  @override
  String get searchHint => 'Search notifications...';

  @override
  String get recentSearches => 'Recent Searches';

  @override
  String get clearAction => 'Clear';

  @override
  String get dateGroupToday => 'Today';

  @override
  String get dateGroupYesterday => 'Yesterday';

  @override
  String get dateGroupThisWeek => 'This Week';

  @override
  String get dateGroupThisMonth => 'This Month';

  @override
  String get dateGroupOlder => 'Older';

  @override
  String get noNotificationsFound => 'No notifications found';

  @override
  String get tryDifferentSearchTerm => 'Try a different search term';

  @override
  String get capturedNotificationsAppearHere =>
      'Captured notifications will appear here';

  @override
  String get notificationDeleted => 'Notification deleted';

  @override
  String get undoAction => 'UNDO';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get filterByDateRange => 'Filter by date range';

  @override
  String get snoozedLabel => 'Snoozed';

  @override
  String get snoozeTooltip => 'Snooze this app';

  @override
  String get snooze1Hour => 'Snooze for 1 hour';

  @override
  String get snooze8Hours => 'Snooze for 8 hours';

  @override
  String get snooze24Hours => 'Snooze for 24 hours';

  @override
  String get cancelSnooze => 'Cancel snooze';

  @override
  String get statStarred => 'Starred';

  @override
  String get noNotifications => 'No notifications';

  @override
  String appUnsnoozed(String appName) {
    return '$appName unsnoozed';
  }

  @override
  String appSnoozed(String appName) {
    return '$appName snoozed';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeLight => 'Light';

  @override
  String get themeSystem => 'System';

  @override
  String get sectionSecurity => 'Security';

  @override
  String get biometricLockTitle => 'Biometric Lock';

  @override
  String get biometricLockSubtitleOn =>
      'Fingerprint, face, or device PIN required to open the app';

  @override
  String get biometricLockSubtitleOff =>
      'Require authentication before viewing your archive';

  @override
  String get sectionQuietHours => 'Quiet Hours';

  @override
  String get enableQuietHours => 'Enable Quiet Hours';

  @override
  String get quietHoursSubtitle =>
      'Pause notification capture during set hours';

  @override
  String get startTime => 'Start Time';

  @override
  String get endTime => 'End Time';

  @override
  String get quietHoursActiveNote =>
      'Quiet hours are currently active — notifications are paused';

  @override
  String get captureActiveNote => 'Notification capture is active';

  @override
  String get sectionKeywordRadar => 'Keyword Radar';

  @override
  String get instantAlertsTitle => 'Instant Alerts';

  @override
  String get instantAlertsSubtitle =>
      'Notify me immediately when a code or priority keyword is captured';

  @override
  String get sectionDataManagement => 'Data Management';

  @override
  String get clearOldNotificationsTitle => 'Clear Old Notifications';

  @override
  String get clearOldNotificationsSubtitle =>
      'Remove notifications older than a set period, right now';

  @override
  String get automaticCleanupTitle => 'Automatic Cleanup';

  @override
  String get automaticCleanupOff => 'Off — notifications are kept forever';

  @override
  String automaticCleanupOn(int days) {
    return 'Auto-deletes notifications older than $days days, checked daily';
  }

  @override
  String get exportNotificationsTitle => 'Export Notifications';

  @override
  String get exportNotificationsSubtitle =>
      'Export all notifications as JSON or CSV';

  @override
  String get clearSearchHistoryTitle => 'Clear Search History';

  @override
  String get clearSearchHistorySubtitle => 'Remove all saved search queries';

  @override
  String get searchHistoryCleared => 'Search history cleared';

  @override
  String get deleteAllNotificationsTitle => 'Delete All Notifications';

  @override
  String get deleteAllNotificationsSubtitle =>
      'Permanently remove all stored notifications';

  @override
  String get sectionBackupRestore => 'Backup & Restore';

  @override
  String get backupNowTitle => 'Backup Now';

  @override
  String get backupNowSubtitle =>
      'Save everything to a file you can store or share';

  @override
  String get restoreFromBackupTitle => 'Restore from Backup';

  @override
  String get restoreFromBackupSubtitle =>
      'Add notifications and settings from a backup file';

  @override
  String get sectionService => 'Service';

  @override
  String get notificationAccessTitle => 'Notification Access';

  @override
  String get notificationAccessSubtitle =>
      'Manage notification listener permission';

  @override
  String get sectionAbout => 'About';

  @override
  String get versionLabel => 'Version 2.0.0';

  @override
  String get featureHeatmap => 'Heatmap';

  @override
  String get featureTags => 'Tags';

  @override
  String get featureQuietHours => 'Quiet Hours';

  @override
  String get featureCopy => 'Copy';

  @override
  String get featureSearchHistory => 'Search History';

  @override
  String get featureAppDetails => 'App Details';

  @override
  String get featureBiometricLock => 'Biometric Lock';

  @override
  String get featureKeywordRadar => 'Keyword Radar';

  @override
  String get featureAutoCleanup => 'Auto-Cleanup';

  @override
  String get featureCodeDetection => 'Code Detection';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get chooseCleanupPeriod =>
      'Choose how far back to keep notifications.';

  @override
  String get keep7Days => 'Keep 7 days';

  @override
  String get keep30Days => 'Keep 30 days';

  @override
  String get keep90Days => 'Keep 90 days';

  @override
  String get cancelAction => 'Cancel';

  @override
  String notificationsDeletedCount(int days) {
    return 'Notifications older than $days days deleted';
  }

  @override
  String get failedToDeleteNotifications => 'Failed to delete notifications';

  @override
  String get deleteAllQuestion => 'Delete All?';

  @override
  String get deleteAllConfirmBody =>
      'This permanently removes every stored notification. This can\'t be undone.';

  @override
  String get allNotificationsDeleted => 'All notifications deleted';

  @override
  String get failedToDelete => 'Failed to delete';

  @override
  String get deleteAllAction => 'Delete All';

  @override
  String get backupPassphraseHint =>
      'Optionally protect the backup with a passphrase. Leave blank for an unencrypted file.';

  @override
  String get passphraseOptionalLabel => 'Passphrase (optional)';

  @override
  String get createBackupAction => 'Create Backup';

  @override
  String backupFailed(String error) {
    return 'Backup failed: $error';
  }

  @override
  String get selectBackupFileTitle =>
      'Select a Notification Keeper backup file';

  @override
  String get restoreExplanation =>
      'This adds the backup\'s notifications to your current archive (nothing is removed first). Leave the passphrase blank if this backup wasn\'t encrypted.';

  @override
  String get passphraseIfEncryptedLabel => 'Passphrase (if encrypted)';

  @override
  String restoredCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'notifications',
      one: 'notification',
    );
    return 'Restored $count $_temp0';
  }

  @override
  String get restoreFailedGeneric => 'Restore failed';

  @override
  String get restoreAction => 'Restore';

  @override
  String get chooseExportFormat => 'Choose a format to export and share.';

  @override
  String get exportFormatJson => 'JSON';

  @override
  String get exportFormatCsv => 'CSV';

  @override
  String get failedToExportNotifications => 'Failed to export notifications';

  @override
  String get automaticCleanupOffToast => 'Automatic cleanup turned off';

  @override
  String automaticCleanupOnToast(int days) {
    return 'Notifications older than $days days will be auto-deleted daily';
  }

  @override
  String get automaticCleanupExplanation =>
      'A background task checks daily and permanently deletes notifications older than this.';

  @override
  String get cleanupOff => 'Off';

  @override
  String get keywordRadarExplanation =>
      'Notifications containing these words are flagged as priority so you can spot them at a glance.';

  @override
  String get keywordHint => 'e.g. urgent, invoice';

  @override
  String get addAction => 'Add';

  @override
  String get days3Short => '3 days';

  @override
  String get days7Short => '7 days';

  @override
  String get days30Short => '30 days';

  @override
  String get days90Short => '90 days';

  @override
  String get navAppsLabel => 'Apps';

  @override
  String get appsSearchHint => 'Search apps...';

  @override
  String get filterAll => 'All';

  @override
  String get filterMonitored => 'Monitored';

  @override
  String get filterOff => 'Off';

  @override
  String get selectAllAction => 'Select All';

  @override
  String get deselectAllAction => 'Deselect All';

  @override
  String get noAppsFound => 'No apps found';

  @override
  String get onboardTitle1 => 'Never Miss a Notification';

  @override
  String get onboardDesc1 =>
      'Notification Keeper captures and archives every notification you receive, so you can review them anytime.';

  @override
  String get onboardTitle2 => 'Complete History';

  @override
  String get onboardDesc2 =>
      'Search, filter, and organize your notification history. Find that important message you accidentally dismissed.';

  @override
  String get onboardTitle3 => 'One Permission Needed';

  @override
  String get onboardDesc3 =>
      'To capture notifications, we need \"Notification Access\" permission. Your data stays on-device and is never shared.';

  @override
  String get openSettingsAction => 'Open Settings';

  @override
  String get iHaveEnabledIt => 'I have enabled it';

  @override
  String get nextAction => 'Next';

  @override
  String get skipAction => 'Skip';

  @override
  String get permissionStillNotEnabled =>
      'Notification access isn\'t showing as enabled yet. Make sure you switched it on for Notification Keeper in the list, then come back.';

  @override
  String get checkingPermission => 'Checking...';

  @override
  String get iosNotSupportedTitle => 'iOS Not Supported';

  @override
  String get iosNotSupportedBody =>
      'iOS does not allow reading notifications from other apps due to system-level restrictions. This feature is only available on Android.';

  @override
  String get justNow => 'Just now';

  @override
  String minutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get noTitle => 'No Title';

  @override
  String get noContent => 'No Content';

  @override
  String get copiedLabel => 'Copied';

  @override
  String categoryLabel(String category) {
    return 'Category: $category';
  }

  @override
  String get tagsLabel => 'Tags';

  @override
  String get starAction => 'Star';

  @override
  String get unstarAction => 'Unstar';

  @override
  String get copyAction => 'Copy';

  @override
  String get deleteAction => 'Delete';

  @override
  String get tagImportant => 'Important';

  @override
  String get tagWork => 'Work';

  @override
  String get tagPersonal => 'Personal';

  @override
  String get tagShopping => 'Shopping';

  @override
  String get tagSocial => 'Social';

  @override
  String get tagNews => 'News';

  @override
  String get tagFinance => 'Finance';

  @override
  String get tagTravel => 'Travel';

  @override
  String get addTagTitle => 'Add Tag';

  @override
  String get enterTagNameHint => 'Enter tag name...';

  @override
  String get suggestionsLabel => 'Suggestions';

  @override
  String get heatmapLess => 'Less';

  @override
  String get heatmapMore => 'More';

  @override
  String heatmapPeak(String time) {
    return 'Peak: $time';
  }

  @override
  String heatmapTooltip(String time, int count) {
    return '$time: $count notifications';
  }

  @override
  String get filterTagged => 'Tagged';

  @override
  String appsMonitoredCount(int monitored, int total) {
    return '$monitored / $total monitored';
  }

  @override
  String quietHoursActiveRange(String start, String end) {
    return 'Active: $start - $end';
  }

  @override
  String quietHoursCapturedToday(int count) {
    return '$count notifications captured quietly during Quiet Hours today';
  }

  @override
  String get filterRecalled => 'Recalled';

  @override
  String get statRecalled => 'Recalled';

  @override
  String get recalledBadge => 'Recalled';

  @override
  String get recalledExplanation =>
      'The sender withdrew this notification moments after it arrived, so the message may have been deleted. Your copy stays here.';

  @override
  String recalledAtLabel(String time) {
    return 'Withdrawn at $time';
  }

  @override
  String get recalledEmptyState => 'Nothing has been withdrawn yet';

  @override
  String get codeShredTitle => 'Auto-shred codes';

  @override
  String get codeShredSubtitle =>
      'Destroy captured verification codes once they expire';

  @override
  String get codeShredExplainer =>
      'A one-time code is useless a minute after it arrives but stays dangerous forever. When the window passes, the digits are wiped from the archive, from exports and from any later backup. The notification itself is kept.';

  @override
  String get codeShredOff => 'Keep codes';

  @override
  String codeShredMinutes(int minutes) {
    return 'After $minutes minutes';
  }

  @override
  String get codeShredHour => 'After 1 hour';

  @override
  String get codeShredDay => 'After 1 day';

  @override
  String codeShredDone(int count) {
    return '$count codes shredded';
  }

  @override
  String get codeShreddedLabel => 'Code shredded';

  @override
  String get filterPhotos => 'Photos';

  @override
  String get sectionPhotos => 'Photos';

  @override
  String get capturePhotosTitle => 'Keep photos from messages';

  @override
  String get capturePhotosSubtitle =>
      'A private copy stays here even if the sender deletes the message';

  @override
  String photoStorageUsage(int count, String size) {
    return '$count photos · $size';
  }

  @override
  String get photoPrivacyNote =>
      'Saved copies are stored privately on this phone, resized, with location and other hidden data removed.';

  @override
  String get deleteAllPhotosTitle => 'Delete all photos';

  @override
  String get deleteAllPhotosBody =>
      'Every stored photo will be removed. The notifications themselves stay in the archive.';

  @override
  String get photosDeleted => 'Photos deleted';

  @override
  String get photoKeptAfterRecall =>
      'The sender deleted this message. The photo is still here.';

  @override
  String get sharePhoto => 'Share photo';

  @override
  String get closeAction => 'Close';
}
