import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('tr'),
  ];

  /// The app's name, shown in the OS task switcher etc.
  ///
  /// In en, this message translates to:
  /// **'Notification Keeper'**
  String get appTitle;

  /// No description provided for @biometricAuthReason.
  ///
  /// In en, this message translates to:
  /// **'Verify your identity to open Notification Keeper'**
  String get biometricAuthReason;

  /// No description provided for @biometricAuthCancelled.
  ///
  /// In en, this message translates to:
  /// **'Authentication was cancelled or failed.'**
  String get biometricAuthCancelled;

  /// No description provided for @biometricNotEnrolled.
  ///
  /// In en, this message translates to:
  /// **'No fingerprint, face, or device PIN enrolled.\nGo to your phone\'s Settings → Security to add one.'**
  String get biometricNotEnrolled;

  /// No description provided for @biometricLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts.\nWait a moment and try again.'**
  String get biometricLockedOut;

  /// No description provided for @biometricNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Biometric hardware is not available on this device.'**
  String get biometricNotAvailable;

  /// No description provided for @lockedTitle.
  ///
  /// In en, this message translates to:
  /// **'LOCKED'**
  String get lockedTitle;

  /// No description provided for @awaitingVerification.
  ///
  /// In en, this message translates to:
  /// **'AWAITING VERIFICATION...'**
  String get awaitingVerification;

  /// No description provided for @archiveProtectedMessage.
  ///
  /// In en, this message translates to:
  /// **'Your notification archive is protected.\nTap the button to unlock.'**
  String get archiveProtectedMessage;

  /// No description provided for @retryButton.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get retryButton;

  /// No description provided for @tapToUnlock.
  ///
  /// In en, this message translates to:
  /// **'TAP TO UNLOCK'**
  String get tapToUnlock;

  /// No description provided for @recentCodesTitle.
  ///
  /// In en, this message translates to:
  /// **'RECENT CODES'**
  String get recentCodesTitle;

  /// No description provided for @tapToCopy.
  ///
  /// In en, this message translates to:
  /// **'Tap to copy'**
  String get tapToCopy;

  /// No description provided for @codeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get codeCopied;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your notification overview'**
  String get dashboardSubtitle;

  /// No description provided for @quietHoursActiveBadge.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get quietHoursActiveBadge;

  /// No description provided for @quietHoursBadge.
  ///
  /// In en, this message translates to:
  /// **'Quiet'**
  String get quietHoursBadge;

  /// No description provided for @statTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get statTotal;

  /// No description provided for @statToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get statToday;

  /// No description provided for @statThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get statThisWeek;

  /// No description provided for @statUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get statUnread;

  /// No description provided for @statCodesToday.
  ///
  /// In en, this message translates to:
  /// **'Codes Today'**
  String get statCodesToday;

  /// No description provided for @statPriorityToday.
  ///
  /// In en, this message translates to:
  /// **'Priority Today'**
  String get statPriorityToday;

  /// No description provided for @weeklyTrend.
  ///
  /// In en, this message translates to:
  /// **'Weekly Trend'**
  String get weeklyTrend;

  /// No description provided for @activityHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Activity Heatmap'**
  String get activityHeatmap;

  /// No description provided for @topApps.
  ///
  /// In en, this message translates to:
  /// **'Top Apps'**
  String get topApps;

  /// No description provided for @recentSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get recentSectionTitle;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// No description provided for @emptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get emptyStateTitle;

  /// No description provided for @emptyStateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications will appear here once captured'**
  String get emptyStateSubtitle;

  /// No description provided for @archiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archiveTitle;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search notifications...'**
  String get searchHint;

  /// No description provided for @recentSearches.
  ///
  /// In en, this message translates to:
  /// **'Recent Searches'**
  String get recentSearches;

  /// No description provided for @clearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clearAction;

  /// No description provided for @dateGroupToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dateGroupToday;

  /// No description provided for @dateGroupYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dateGroupYesterday;

  /// No description provided for @dateGroupThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get dateGroupThisWeek;

  /// No description provided for @dateGroupThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get dateGroupThisMonth;

  /// No description provided for @dateGroupOlder.
  ///
  /// In en, this message translates to:
  /// **'Older'**
  String get dateGroupOlder;

  /// No description provided for @noNotificationsFound.
  ///
  /// In en, this message translates to:
  /// **'No notifications found'**
  String get noNotificationsFound;

  /// No description provided for @tryDifferentSearchTerm.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearchTerm;

  /// No description provided for @capturedNotificationsAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Captured notifications will appear here'**
  String get capturedNotificationsAppearHere;

  /// No description provided for @notificationDeleted.
  ///
  /// In en, this message translates to:
  /// **'Notification deleted'**
  String get notificationDeleted;

  /// No description provided for @undoAction.
  ///
  /// In en, this message translates to:
  /// **'UNDO'**
  String get undoAction;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @filterByDateRange.
  ///
  /// In en, this message translates to:
  /// **'Filter by date range'**
  String get filterByDateRange;

  /// No description provided for @snoozedLabel.
  ///
  /// In en, this message translates to:
  /// **'Snoozed'**
  String get snoozedLabel;

  /// No description provided for @snoozeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Snooze this app'**
  String get snoozeTooltip;

  /// No description provided for @snooze1Hour.
  ///
  /// In en, this message translates to:
  /// **'Snooze for 1 hour'**
  String get snooze1Hour;

  /// No description provided for @snooze8Hours.
  ///
  /// In en, this message translates to:
  /// **'Snooze for 8 hours'**
  String get snooze8Hours;

  /// No description provided for @snooze24Hours.
  ///
  /// In en, this message translates to:
  /// **'Snooze for 24 hours'**
  String get snooze24Hours;

  /// No description provided for @cancelSnooze.
  ///
  /// In en, this message translates to:
  /// **'Cancel snooze'**
  String get cancelSnooze;

  /// No description provided for @statStarred.
  ///
  /// In en, this message translates to:
  /// **'Starred'**
  String get statStarred;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @appUnsnoozed.
  ///
  /// In en, this message translates to:
  /// **'{appName} unsnoozed'**
  String appUnsnoozed(String appName);

  /// No description provided for @appSnoozed.
  ///
  /// In en, this message translates to:
  /// **'{appName} snoozed'**
  String appSnoozed(String appName);

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get sectionAppearance;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @sectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get sectionSecurity;

  /// No description provided for @biometricLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Biometric Lock'**
  String get biometricLockTitle;

  /// No description provided for @biometricLockSubtitleOn.
  ///
  /// In en, this message translates to:
  /// **'Fingerprint, face, or device PIN required to open the app'**
  String get biometricLockSubtitleOn;

  /// No description provided for @biometricLockSubtitleOff.
  ///
  /// In en, this message translates to:
  /// **'Require authentication before viewing your archive'**
  String get biometricLockSubtitleOff;

  /// No description provided for @sectionQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours'**
  String get sectionQuietHours;

  /// No description provided for @enableQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Enable Quiet Hours'**
  String get enableQuietHours;

  /// No description provided for @quietHoursSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pause notification capture during set hours'**
  String get quietHoursSubtitle;

  /// No description provided for @startTime.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get startTime;

  /// No description provided for @endTime.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get endTime;

  /// No description provided for @quietHoursActiveNote.
  ///
  /// In en, this message translates to:
  /// **'Quiet hours are currently active — notifications are paused'**
  String get quietHoursActiveNote;

  /// No description provided for @captureActiveNote.
  ///
  /// In en, this message translates to:
  /// **'Notification capture is active'**
  String get captureActiveNote;

  /// No description provided for @sectionKeywordRadar.
  ///
  /// In en, this message translates to:
  /// **'Keyword Radar'**
  String get sectionKeywordRadar;

  /// No description provided for @instantAlertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Instant Alerts'**
  String get instantAlertsTitle;

  /// No description provided for @instantAlertsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Notify me immediately when a code or priority keyword is captured'**
  String get instantAlertsSubtitle;

  /// No description provided for @sectionDataManagement.
  ///
  /// In en, this message translates to:
  /// **'Data Management'**
  String get sectionDataManagement;

  /// No description provided for @clearOldNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Old Notifications'**
  String get clearOldNotificationsTitle;

  /// No description provided for @clearOldNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove notifications older than a set period, right now'**
  String get clearOldNotificationsSubtitle;

  /// No description provided for @automaticCleanupTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatic Cleanup'**
  String get automaticCleanupTitle;

  /// No description provided for @automaticCleanupOff.
  ///
  /// In en, this message translates to:
  /// **'Off — notifications are kept forever'**
  String get automaticCleanupOff;

  /// No description provided for @automaticCleanupOn.
  ///
  /// In en, this message translates to:
  /// **'Auto-deletes notifications older than {days} days, checked daily'**
  String automaticCleanupOn(int days);

  /// No description provided for @exportNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Notifications'**
  String get exportNotificationsTitle;

  /// No description provided for @exportNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Export all notifications as JSON or CSV'**
  String get exportNotificationsSubtitle;

  /// No description provided for @clearSearchHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear Search History'**
  String get clearSearchHistoryTitle;

  /// No description provided for @clearSearchHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Remove all saved search queries'**
  String get clearSearchHistorySubtitle;

  /// No description provided for @searchHistoryCleared.
  ///
  /// In en, this message translates to:
  /// **'Search history cleared'**
  String get searchHistoryCleared;

  /// No description provided for @deleteAllNotificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete All Notifications'**
  String get deleteAllNotificationsTitle;

  /// No description provided for @deleteAllNotificationsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently remove all stored notifications'**
  String get deleteAllNotificationsSubtitle;

  /// No description provided for @sectionBackupRestore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get sectionBackupRestore;

  /// No description provided for @backupNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Backup Now'**
  String get backupNowTitle;

  /// No description provided for @backupNowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save everything to a file you can store or share'**
  String get backupNowSubtitle;

  /// No description provided for @restoreFromBackupTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore from Backup'**
  String get restoreFromBackupTitle;

  /// No description provided for @restoreFromBackupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add notifications and settings from a backup file'**
  String get restoreFromBackupSubtitle;

  /// No description provided for @sectionService.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get sectionService;

  /// No description provided for @notificationAccessTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification Access'**
  String get notificationAccessTitle;

  /// No description provided for @notificationAccessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage notification listener permission'**
  String get notificationAccessSubtitle;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version 2.0.0'**
  String get versionLabel;

  /// No description provided for @featureHeatmap.
  ///
  /// In en, this message translates to:
  /// **'Heatmap'**
  String get featureHeatmap;

  /// No description provided for @featureTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get featureTags;

  /// No description provided for @featureQuietHours.
  ///
  /// In en, this message translates to:
  /// **'Quiet Hours'**
  String get featureQuietHours;

  /// No description provided for @featureCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get featureCopy;

  /// No description provided for @featureSearchHistory.
  ///
  /// In en, this message translates to:
  /// **'Search History'**
  String get featureSearchHistory;

  /// No description provided for @featureAppDetails.
  ///
  /// In en, this message translates to:
  /// **'App Details'**
  String get featureAppDetails;

  /// No description provided for @featureBiometricLock.
  ///
  /// In en, this message translates to:
  /// **'Biometric Lock'**
  String get featureBiometricLock;

  /// No description provided for @featureKeywordRadar.
  ///
  /// In en, this message translates to:
  /// **'Keyword Radar'**
  String get featureKeywordRadar;

  /// No description provided for @featureAutoCleanup.
  ///
  /// In en, this message translates to:
  /// **'Auto-Cleanup'**
  String get featureAutoCleanup;

  /// No description provided for @featureCodeDetection.
  ///
  /// In en, this message translates to:
  /// **'Code Detection'**
  String get featureCodeDetection;

  /// No description provided for @sectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get sectionLanguage;

  /// No description provided for @chooseCleanupPeriod.
  ///
  /// In en, this message translates to:
  /// **'Choose how far back to keep notifications.'**
  String get chooseCleanupPeriod;

  /// No description provided for @keep7Days.
  ///
  /// In en, this message translates to:
  /// **'Keep 7 days'**
  String get keep7Days;

  /// No description provided for @keep30Days.
  ///
  /// In en, this message translates to:
  /// **'Keep 30 days'**
  String get keep30Days;

  /// No description provided for @keep90Days.
  ///
  /// In en, this message translates to:
  /// **'Keep 90 days'**
  String get keep90Days;

  /// No description provided for @cancelAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancelAction;

  /// No description provided for @notificationsDeletedCount.
  ///
  /// In en, this message translates to:
  /// **'Notifications older than {days} days deleted'**
  String notificationsDeletedCount(int days);

  /// No description provided for @failedToDeleteNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete notifications'**
  String get failedToDeleteNotifications;

  /// No description provided for @deleteAllQuestion.
  ///
  /// In en, this message translates to:
  /// **'Delete All?'**
  String get deleteAllQuestion;

  /// No description provided for @deleteAllConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes every stored notification. This can\'t be undone.'**
  String get deleteAllConfirmBody;

  /// No description provided for @allNotificationsDeleted.
  ///
  /// In en, this message translates to:
  /// **'All notifications deleted'**
  String get allNotificationsDeleted;

  /// No description provided for @failedToDelete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete'**
  String get failedToDelete;

  /// No description provided for @deleteAllAction.
  ///
  /// In en, this message translates to:
  /// **'Delete All'**
  String get deleteAllAction;

  /// No description provided for @backupPassphraseHint.
  ///
  /// In en, this message translates to:
  /// **'Optionally protect the backup with a passphrase. Leave blank for an unencrypted file.'**
  String get backupPassphraseHint;

  /// No description provided for @passphraseOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Passphrase (optional)'**
  String get passphraseOptionalLabel;

  /// No description provided for @createBackupAction.
  ///
  /// In en, this message translates to:
  /// **'Create Backup'**
  String get createBackupAction;

  /// No description provided for @backupFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed: {error}'**
  String backupFailed(String error);

  /// No description provided for @selectBackupFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Select a Notification Keeper backup file'**
  String get selectBackupFileTitle;

  /// No description provided for @restoreExplanation.
  ///
  /// In en, this message translates to:
  /// **'This adds the backup\'s notifications to your current archive (nothing is removed first). Leave the passphrase blank if this backup wasn\'t encrypted.'**
  String get restoreExplanation;

  /// No description provided for @passphraseIfEncryptedLabel.
  ///
  /// In en, this message translates to:
  /// **'Passphrase (if encrypted)'**
  String get passphraseIfEncryptedLabel;

  /// No description provided for @restoredCount.
  ///
  /// In en, this message translates to:
  /// **'Restored {count} {count, plural, =1{notification} other{notifications}}'**
  String restoredCount(int count);

  /// No description provided for @restoreFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Restore failed'**
  String get restoreFailedGeneric;

  /// No description provided for @restoreAction.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restoreAction;

  /// No description provided for @chooseExportFormat.
  ///
  /// In en, this message translates to:
  /// **'Choose a format to export and share.'**
  String get chooseExportFormat;

  /// No description provided for @exportFormatJson.
  ///
  /// In en, this message translates to:
  /// **'JSON'**
  String get exportFormatJson;

  /// No description provided for @exportFormatCsv.
  ///
  /// In en, this message translates to:
  /// **'CSV'**
  String get exportFormatCsv;

  /// No description provided for @failedToExportNotifications.
  ///
  /// In en, this message translates to:
  /// **'Failed to export notifications'**
  String get failedToExportNotifications;

  /// No description provided for @automaticCleanupOffToast.
  ///
  /// In en, this message translates to:
  /// **'Automatic cleanup turned off'**
  String get automaticCleanupOffToast;

  /// No description provided for @automaticCleanupOnToast.
  ///
  /// In en, this message translates to:
  /// **'Notifications older than {days} days will be auto-deleted daily'**
  String automaticCleanupOnToast(int days);

  /// No description provided for @automaticCleanupExplanation.
  ///
  /// In en, this message translates to:
  /// **'A background task checks daily and permanently deletes notifications older than this.'**
  String get automaticCleanupExplanation;

  /// No description provided for @cleanupOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get cleanupOff;

  /// No description provided for @keywordRadarExplanation.
  ///
  /// In en, this message translates to:
  /// **'Notifications containing these words are flagged as priority so you can spot them at a glance.'**
  String get keywordRadarExplanation;

  /// No description provided for @keywordHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. urgent, invoice'**
  String get keywordHint;

  /// No description provided for @addAction.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addAction;

  /// No description provided for @days3Short.
  ///
  /// In en, this message translates to:
  /// **'3 days'**
  String get days3Short;

  /// No description provided for @days7Short.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get days7Short;

  /// No description provided for @days30Short.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get days30Short;

  /// No description provided for @days90Short.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get days90Short;

  /// No description provided for @navAppsLabel.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get navAppsLabel;

  /// No description provided for @appsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search apps...'**
  String get appsSearchHint;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterMonitored.
  ///
  /// In en, this message translates to:
  /// **'Monitored'**
  String get filterMonitored;

  /// No description provided for @filterOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get filterOff;

  /// No description provided for @selectAllAction.
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get selectAllAction;

  /// No description provided for @deselectAllAction.
  ///
  /// In en, this message translates to:
  /// **'Deselect All'**
  String get deselectAllAction;

  /// No description provided for @noAppsFound.
  ///
  /// In en, this message translates to:
  /// **'No apps found'**
  String get noAppsFound;

  /// No description provided for @onboardTitle1.
  ///
  /// In en, this message translates to:
  /// **'Never Miss a Notification'**
  String get onboardTitle1;

  /// No description provided for @onboardDesc1.
  ///
  /// In en, this message translates to:
  /// **'Notification Keeper captures and archives every notification you receive, so you can review them anytime.'**
  String get onboardDesc1;

  /// No description provided for @onboardTitle2.
  ///
  /// In en, this message translates to:
  /// **'Complete History'**
  String get onboardTitle2;

  /// No description provided for @onboardDesc2.
  ///
  /// In en, this message translates to:
  /// **'Search, filter, and organize your notification history. Find that important message you accidentally dismissed.'**
  String get onboardDesc2;

  /// No description provided for @onboardTitle3.
  ///
  /// In en, this message translates to:
  /// **'One Permission Needed'**
  String get onboardTitle3;

  /// No description provided for @onboardDesc3.
  ///
  /// In en, this message translates to:
  /// **'To capture notifications, we need \"Notification Access\" permission. Your data stays on-device and is never shared.'**
  String get onboardDesc3;

  /// No description provided for @openSettingsAction.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get openSettingsAction;

  /// No description provided for @iHaveEnabledIt.
  ///
  /// In en, this message translates to:
  /// **'I have enabled it'**
  String get iHaveEnabledIt;

  /// No description provided for @nextAction.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextAction;

  /// No description provided for @skipAction.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skipAction;

  /// No description provided for @permissionStillNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Notification access isn\'t showing as enabled yet. Make sure you switched it on for Notification Keeper in the list, then come back.'**
  String get permissionStillNotEnabled;

  /// No description provided for @checkingPermission.
  ///
  /// In en, this message translates to:
  /// **'Checking...'**
  String get checkingPermission;

  /// No description provided for @iosNotSupportedTitle.
  ///
  /// In en, this message translates to:
  /// **'iOS Not Supported'**
  String get iosNotSupportedTitle;

  /// No description provided for @iosNotSupportedBody.
  ///
  /// In en, this message translates to:
  /// **'iOS does not allow reading notifications from other apps due to system-level restrictions. This feature is only available on Android.'**
  String get iosNotSupportedBody;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String minutesAgo(int minutes);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String hoursAgo(int hours);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String daysAgo(int days);

  /// No description provided for @noTitle.
  ///
  /// In en, this message translates to:
  /// **'No Title'**
  String get noTitle;

  /// No description provided for @noContent.
  ///
  /// In en, this message translates to:
  /// **'No Content'**
  String get noContent;

  /// No description provided for @copiedLabel.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copiedLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category: {category}'**
  String categoryLabel(String category);

  /// No description provided for @tagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsLabel;

  /// No description provided for @starAction.
  ///
  /// In en, this message translates to:
  /// **'Star'**
  String get starAction;

  /// No description provided for @unstarAction.
  ///
  /// In en, this message translates to:
  /// **'Unstar'**
  String get unstarAction;

  /// No description provided for @copyAction.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyAction;

  /// No description provided for @deleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAction;

  /// No description provided for @tagImportant.
  ///
  /// In en, this message translates to:
  /// **'Important'**
  String get tagImportant;

  /// No description provided for @tagWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get tagWork;

  /// No description provided for @tagPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get tagPersonal;

  /// No description provided for @tagShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get tagShopping;

  /// No description provided for @tagSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get tagSocial;

  /// No description provided for @tagNews.
  ///
  /// In en, this message translates to:
  /// **'News'**
  String get tagNews;

  /// No description provided for @tagFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get tagFinance;

  /// No description provided for @tagTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get tagTravel;

  /// No description provided for @addTagTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Tag'**
  String get addTagTitle;

  /// No description provided for @enterTagNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter tag name...'**
  String get enterTagNameHint;

  /// No description provided for @suggestionsLabel.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get suggestionsLabel;

  /// No description provided for @heatmapLess.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get heatmapLess;

  /// No description provided for @heatmapMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get heatmapMore;

  /// No description provided for @heatmapPeak.
  ///
  /// In en, this message translates to:
  /// **'Peak: {time}'**
  String heatmapPeak(String time);

  /// No description provided for @heatmapTooltip.
  ///
  /// In en, this message translates to:
  /// **'{time}: {count} notifications'**
  String heatmapTooltip(String time, int count);

  /// No description provided for @filterTagged.
  ///
  /// In en, this message translates to:
  /// **'Tagged'**
  String get filterTagged;

  /// No description provided for @appsMonitoredCount.
  ///
  /// In en, this message translates to:
  /// **'{monitored} / {total} monitored'**
  String appsMonitoredCount(int monitored, int total);

  /// No description provided for @quietHoursActiveRange.
  ///
  /// In en, this message translates to:
  /// **'Active: {start} - {end}'**
  String quietHoursActiveRange(String start, String end);

  /// No description provided for @quietHoursCapturedToday.
  ///
  /// In en, this message translates to:
  /// **'{count} notifications captured quietly during Quiet Hours today'**
  String quietHoursCapturedToday(int count);

  /// No description provided for @filterRecalled.
  ///
  /// In en, this message translates to:
  /// **'Recalled'**
  String get filterRecalled;

  /// No description provided for @statRecalled.
  ///
  /// In en, this message translates to:
  /// **'Recalled'**
  String get statRecalled;

  /// No description provided for @recalledBadge.
  ///
  /// In en, this message translates to:
  /// **'Recalled'**
  String get recalledBadge;

  /// No description provided for @recalledExplanation.
  ///
  /// In en, this message translates to:
  /// **'The sender withdrew this notification moments after it arrived, so the message may have been deleted. Your copy stays here.'**
  String get recalledExplanation;

  /// No description provided for @recalledAtLabel.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn at {time}'**
  String recalledAtLabel(String time);

  /// No description provided for @recalledEmptyState.
  ///
  /// In en, this message translates to:
  /// **'Nothing has been withdrawn yet'**
  String get recalledEmptyState;

  /// No description provided for @codeShredTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-shred codes'**
  String get codeShredTitle;

  /// No description provided for @codeShredSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Destroy captured verification codes once they expire'**
  String get codeShredSubtitle;

  /// No description provided for @codeShredExplainer.
  ///
  /// In en, this message translates to:
  /// **'A one-time code is useless a minute after it arrives but stays dangerous forever. When the window passes, the digits are wiped from the archive, from exports and from any later backup. The notification itself is kept.'**
  String get codeShredExplainer;

  /// No description provided for @codeShredOff.
  ///
  /// In en, this message translates to:
  /// **'Keep codes'**
  String get codeShredOff;

  /// No description provided for @codeShredMinutes.
  ///
  /// In en, this message translates to:
  /// **'After {minutes} minutes'**
  String codeShredMinutes(int minutes);

  /// No description provided for @codeShredHour.
  ///
  /// In en, this message translates to:
  /// **'After 1 hour'**
  String get codeShredHour;

  /// No description provided for @codeShredDay.
  ///
  /// In en, this message translates to:
  /// **'After 1 day'**
  String get codeShredDay;

  /// No description provided for @codeShredDone.
  ///
  /// In en, this message translates to:
  /// **'{count} codes shredded'**
  String codeShredDone(int count);

  /// No description provided for @codeShreddedLabel.
  ///
  /// In en, this message translates to:
  /// **'Code shredded'**
  String get codeShreddedLabel;

  /// No description provided for @filterPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get filterPhotos;

  /// No description provided for @sectionPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get sectionPhotos;

  /// No description provided for @capturePhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep photos from messages'**
  String get capturePhotosTitle;

  /// No description provided for @capturePhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A private copy stays here even if the sender deletes the message'**
  String get capturePhotosSubtitle;

  /// No description provided for @photoStorageUsage.
  ///
  /// In en, this message translates to:
  /// **'{count} photos · {size}'**
  String photoStorageUsage(int count, String size);

  /// No description provided for @photoPrivacyNote.
  ///
  /// In en, this message translates to:
  /// **'Saved copies are stored privately on this phone, resized, with location and other hidden data removed.'**
  String get photoPrivacyNote;

  /// No description provided for @deleteAllPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all photos'**
  String get deleteAllPhotosTitle;

  /// No description provided for @deleteAllPhotosBody.
  ///
  /// In en, this message translates to:
  /// **'Every stored photo will be removed. The notifications themselves stay in the archive.'**
  String get deleteAllPhotosBody;

  /// No description provided for @photosDeleted.
  ///
  /// In en, this message translates to:
  /// **'Photos deleted'**
  String get photosDeleted;

  /// No description provided for @photoKeptAfterRecall.
  ///
  /// In en, this message translates to:
  /// **'The sender deleted this message. The photo is still here.'**
  String get photoKeptAfterRecall;

  /// No description provided for @sharePhoto.
  ///
  /// In en, this message translates to:
  /// **'Share photo'**
  String get sharePhoto;

  /// No description provided for @closeAction.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeAction;

  /// No description provided for @showSystemApps.
  ///
  /// In en, this message translates to:
  /// **'Show system apps'**
  String get showSystemApps;

  /// No description provided for @vaultLockedTitle.
  ///
  /// In en, this message translates to:
  /// **'Vault locked'**
  String get vaultLockedTitle;

  /// No description provided for @vaultEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your vault PIN'**
  String get vaultEnterPin;

  /// No description provided for @vaultUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get vaultUnlock;

  /// No description provided for @vaultWrongPin.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Wrong PIN. 1 attempt left} other{Wrong PIN. {count} attempts left}}'**
  String vaultWrongPin(int count);

  /// No description provided for @vaultLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in {time}'**
  String vaultLockedOut(String time);

  /// No description provided for @vaultForgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get vaultForgotPin;

  /// No description provided for @vaultForgotPinReason.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you to set a new vault PIN'**
  String get vaultForgotPinReason;

  /// No description provided for @vaultBiometricChanged.
  ///
  /// In en, this message translates to:
  /// **'The fingerprints on this phone changed since you turned on fingerprint unlock. Enter your PIN to use them again.'**
  String get vaultBiometricChanged;

  /// No description provided for @vaultUseFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint'**
  String get vaultUseFingerprint;

  /// No description provided for @vaultBiometricReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock Notification Keeper'**
  String get vaultBiometricReason;

  /// No description provided for @deleteDigit.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteDigit;

  /// No description provided for @vaultSetupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your vault PIN'**
  String get vaultSetupTitle;

  /// No description provided for @vaultSetupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'4 to 8 digits. You will use it to open the archive.'**
  String get vaultSetupSubtitle;

  /// No description provided for @vaultConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter it again'**
  String get vaultConfirmTitle;

  /// No description provided for @vaultPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'The PINs did not match. Try again.'**
  String get vaultPinMismatch;

  /// No description provided for @vaultContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get vaultContinue;

  /// No description provided for @vaultBiometricOfferTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock with fingerprint?'**
  String get vaultBiometricOfferTitle;

  /// No description provided for @vaultBiometricOfferBody.
  ///
  /// In en, this message translates to:
  /// **'Every fingerprint saved on this phone will open the vault. If someone adds a new one, the vault notices and asks for your PIN first.'**
  String get vaultBiometricOfferBody;

  /// No description provided for @vaultBiometricYes.
  ///
  /// In en, this message translates to:
  /// **'Use fingerprint'**
  String get vaultBiometricYes;

  /// No description provided for @vaultBiometricNo.
  ///
  /// In en, this message translates to:
  /// **'PIN only'**
  String get vaultBiometricNo;

  /// No description provided for @vaultNoBiometricEnrolled.
  ///
  /// In en, this message translates to:
  /// **'No fingerprint is saved on this phone yet. Add one in Android settings, then come back.'**
  String get vaultNoBiometricEnrolled;

  /// No description provided for @vaultAddFingerprint.
  ///
  /// In en, this message translates to:
  /// **'Add a fingerprint'**
  String get vaultAddFingerprint;

  /// No description provided for @vaultSetupDone.
  ///
  /// In en, this message translates to:
  /// **'Vault is on'**
  String get vaultSetupDone;

  /// No description provided for @vaultLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Vault lock'**
  String get vaultLockTitle;

  /// No description provided for @vaultLockOnSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A PIN is needed to open the archive'**
  String get vaultLockOnSubtitle;

  /// No description provided for @vaultLockOffSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Anyone holding your unlocked phone can open the archive'**
  String get vaultLockOffSubtitle;

  /// No description provided for @vaultChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get vaultChangePin;

  /// No description provided for @vaultFingerprintUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock with fingerprint'**
  String get vaultFingerprintUnlock;

  /// No description provided for @vaultManageFingerprints.
  ///
  /// In en, this message translates to:
  /// **'Add or manage fingerprints'**
  String get vaultManageFingerprints;

  /// No description provided for @vaultManageFingerprintsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Opens Android\'s fingerprint settings. Every finger saved there unlocks the vault.'**
  String get vaultManageFingerprintsSubtitle;

  /// No description provided for @vaultExplainer.
  ///
  /// In en, this message translates to:
  /// **'Fingerprints never leave Android\'s secure hardware: this app cannot see or store them. A forgotten PIN can be reset with the phone\'s screen lock, so the vault is as strong as that screen lock. The archive is kept in the app\'s private storage and is not separately encrypted.'**
  String get vaultExplainer;

  /// No description provided for @vaultConfirmPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your current PIN'**
  String get vaultConfirmPinTitle;

  /// No description provided for @vaultPinChanged.
  ///
  /// In en, this message translates to:
  /// **'PIN changed'**
  String get vaultPinChanged;

  /// No description provided for @vaultTurnedOff.
  ///
  /// In en, this message translates to:
  /// **'Vault turned off'**
  String get vaultTurnedOff;

  /// No description provided for @vaultUpgradeTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a vault PIN'**
  String get vaultUpgradeTitle;

  /// No description provided for @vaultUpgradeBody.
  ///
  /// In en, this message translates to:
  /// **'Your lock currently relies on the phone\'s screen lock. A PIN of the vault\'s own is stronger.'**
  String get vaultUpgradeBody;

  /// No description provided for @laterAction.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get laterAction;

  /// No description provided for @vaultNewPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a new PIN'**
  String get vaultNewPinTitle;

  /// No description provided for @vaultUsePin.
  ///
  /// In en, this message translates to:
  /// **'Use PIN'**
  String get vaultUsePin;

  /// No description provided for @vaultFingerprintLockedOut.
  ///
  /// In en, this message translates to:
  /// **'Too many fingerprint tries. Use your PIN.'**
  String get vaultFingerprintLockedOut;

  /// No description provided for @vaultForgotNeedsScreenLock.
  ///
  /// In en, this message translates to:
  /// **'Resetting the PIN needs your phone\'s screen lock, and this phone has none. Set one in Android settings first.'**
  String get vaultForgotNeedsScreenLock;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
