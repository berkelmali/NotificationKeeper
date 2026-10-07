import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/presentation/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Fresh, empty prefs before every test - avoids state leaking between
    // tests and matches a first-ever app launch.
    SharedPreferences.setMockInitialValues({});
  });

  group('Retention (Data Hygiene / BurnerWorker)', () {
    test('defaults to 0 (keep forever) on a fresh install', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();
      expect(settings.retentionDays, 0);
    });

    test('setRetentionDays updates state and persists across a reload', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();

      await settings.setRetentionDays(30);
      expect(settings.retentionDays, 30);

      // Simulate the app restarting: a brand-new provider reading the
      // same underlying SharedPreferences store.
      final reloaded = SettingsProvider();
      await reloaded.loadSettings();
      expect(reloaded.retentionDays, 30);
    });
  });

  group('Keyword Radar', () {
    test('starts empty', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();
      expect(settings.priorityKeywords, isEmpty);
    });

    test('addPriorityKeyword adds a trimmed keyword', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();

      await settings.addPriorityKeyword('  urgent  ');

      expect(settings.priorityKeywords, ['urgent']);
    });

    test('addPriorityKeyword ignores duplicates', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();

      await settings.addPriorityKeyword('urgent');
      await settings.addPriorityKeyword('urgent');

      expect(settings.priorityKeywords, ['urgent']);
    });

    test('addPriorityKeyword ignores an empty/whitespace-only entry', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();

      await settings.addPriorityKeyword('   ');

      expect(settings.priorityKeywords, isEmpty);
    });

    test('removePriorityKeyword removes exactly one entry', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();

      await settings.addPriorityKeyword('urgent');
      await settings.addPriorityKeyword('invoice');
      await settings.removePriorityKeyword('urgent');

      expect(settings.priorityKeywords, ['invoice']);
    });

    test('keyword list persists across a reload', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();
      await settings.addPriorityKeyword('billing');

      final reloaded = SettingsProvider();
      await reloaded.loadSettings();

      expect(reloaded.priorityKeywords, ['billing']);
    });
  });

  group('Biometric Lock', () {
    test('defaults to OFF so existing users are never locked out unexpectedly '
        'by an update alone', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();
      expect(settings.biometricLockEnabled, false);
    });

    test('setBiometricLockEnabled(true) persists across a reload', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();
      await settings.setBiometricLockEnabled(true);

      final reloaded = SettingsProvider();
      await reloaded.loadSettings();
      expect(reloaded.biometricLockEnabled, true);
    });
  });

  group('Instant Alerts', () {
    test('defaults to ON (opt-out, not opt-in) since it directly serves '
        'the "you just got a code" value of the app', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();
      expect(settings.instantAlertsEnabled, true);
    });

    test('can be turned off and that choice persists', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();
      await settings.setInstantAlertsEnabled(false);

      final reloaded = SettingsProvider();
      await reloaded.loadSettings();
      expect(reloaded.instantAlertsEnabled, false);
    });
  });

  group('Language selection', () {
    test('defaults to null (follow system language)', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();
      expect(settings.appLocale, isNull);
    });

    test('setAppLocale persists the chosen language code', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();
      await settings.setAppLocale(const Locale('tr'));

      final reloaded = SettingsProvider();
      await reloaded.loadSettings();
      expect(reloaded.appLocale?.languageCode, 'tr');
    });

    test('setAppLocale(null) clears back to "follow system"', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();
      await settings.setAppLocale(const Locale('en'));
      await settings.setAppLocale(null);

      final reloaded = SettingsProvider();
      await reloaded.loadSettings();
      expect(reloaded.appLocale, isNull);
    });
  });

  group('Code Shredder (new feature B)', () {
    test('defaults to 0 (keep codes) - destroying data is never the default '
        'for an existing user who never asked for it', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();
      expect(settings.otpShredMinutes, 0);
    });

    test('setOtpShredMinutes persists the chosen window across a restart', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();

      await settings.setOtpShredMinutes(15);
      expect(settings.otpShredMinutes, 15);

      final reloaded = SettingsProvider();
      await reloaded.loadSettings();
      expect(reloaded.otpShredMinutes, 15);
    });

    test('can be switched back off again', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();
      await settings.setOtpShredMinutes(60);
      await settings.setOtpShredMinutes(0);

      final reloaded = SettingsProvider();
      await reloaded.loadSettings();
      expect(reloaded.otpShredMinutes, 0);
    });

    test('notifies listeners so the settings card redraws immediately', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();

      var notified = 0;
      settings.addListener(() => notified++);
      await settings.setOtpShredMinutes(5);

      expect(notified, greaterThan(0));
    });
  });

  group('Photo vault', () {
    test('keeps photos by default, because the user asked for exactly that', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();
      expect(settings.capturePhotos, true);
    });

    test('turning it off persists across a restart', () async {
      final settings = SettingsProvider();
      await settings.loadSettings();
      await settings.setCapturePhotos(false);

      final reloaded = SettingsProvider();
      await reloaded.loadSettings();
      expect(reloaded.capturePhotos, false);
    });
  });
}
