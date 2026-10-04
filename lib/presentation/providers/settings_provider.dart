import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _isLoaded = false;

  // ─── Quiet Hours (Feature 6: Notisave Clone) ───
  bool _quietHoursEnabled = false;
  TimeOfDay _quietHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietHoursEnd = const TimeOfDay(hour: 7, minute: 0);

  // ─── Search History (Feature 1: Unique) ───
  List<String> _searchHistory = [];
  static const int _maxSearchHistory = 10;

  // ─── Merged from base.apk (com.example.fluter): Data Hygiene / retention ───
  int _retentionDays = 0; // 0 = keep forever

  // ─── Merged from base.apk (com.example.fluter): Keyword Radar ───
  List<String> _priorityKeywords = [];

  // ─── Merged from base.apk (com.example.fluter): Biometric Vault lock ───
  bool _biometricLockEnabled = false;

  // ─── New feature: instant local alerts for OTP/priority captures ───
  bool _instantAlertsEnabled = true;

  // ─── New feature B: Code Shredder. Minutes a captured verification code is
  // kept before its digits are destroyed. 0 = keep codes (shredder off). ───
  int _otpShredMinutes = 0;

  // ─── Photo vault: keep pictures from notifications. On by default. ───
  bool _capturePhotos = true;

  // ─── New feature: multi-language support. null = follow system language ───
  Locale? _appLocale;

  ThemeMode get themeMode => _themeMode;
  bool get isLoaded => _isLoaded;
  bool get quietHoursEnabled => _quietHoursEnabled;
  TimeOfDay get quietHoursStart => _quietHoursStart;
  TimeOfDay get quietHoursEnd => _quietHoursEnd;
  List<String> get searchHistory => _searchHistory;
  int get retentionDays => _retentionDays;
  List<String> get priorityKeywords => _priorityKeywords;
  bool get biometricLockEnabled => _biometricLockEnabled;
  bool get instantAlertsEnabled => _instantAlertsEnabled;
  int get otpShredMinutes => _otpShredMinutes;
  bool get capturePhotos => _capturePhotos;
  Locale? get appLocale => _appLocale;

  Future<void> setAppLocale(Locale? locale) async {
    _appLocale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove('appLocaleCode');
    } else {
      await prefs.setString('appLocaleCode', locale.languageCode);
    }
  }

  /// Check if quiet hours are currently active
  bool get isQuietHoursActive {
    if (!_quietHoursEnabled) return false;
    final now = TimeOfDay.now();
    final nowMinutes = now.hour * 60 + now.minute;
    final startMinutes = _quietHoursStart.hour * 60 + _quietHoursStart.minute;
    final endMinutes = _quietHoursEnd.hour * 60 + _quietHoursEnd.minute;

    if (startMinutes <= endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
    } else {
      // Overnight range (e.g. 22:00 - 07:00)
      return nowMinutes >= startMinutes || nowMinutes <= endMinutes;
    }
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeStr = prefs.getString('themeMode') ?? 'dark';
    _themeMode = _themeModeFromString(themeModeStr);

    // Quiet Hours
    _quietHoursEnabled = prefs.getBool('quietHoursEnabled') ?? false;
    _quietHoursStart = TimeOfDay(
      hour: prefs.getInt('quietHoursStartHour') ?? 22,
      minute: prefs.getInt('quietHoursStartMinute') ?? 0,
    );
    _quietHoursEnd = TimeOfDay(
      hour: prefs.getInt('quietHoursEndHour') ?? 7,
      minute: prefs.getInt('quietHoursEndMinute') ?? 0,
    );

    // Search History
    _searchHistory = prefs.getStringList('searchHistory') ?? [];

    // Merged from base.apk: Data Hygiene / retention
    _retentionDays = prefs.getInt('retentionDays') ?? 0;

    // Merged from base.apk: Keyword Radar
    _priorityKeywords = prefs.getStringList('priorityKeywords') ?? [];

    // Merged from base.apk: Biometric Vault lock
    _biometricLockEnabled = prefs.getBool('biometricLockEnabled') ?? false;

    // New feature: instant local alerts
    _instantAlertsEnabled = prefs.getBool('instantAlertsEnabled') ?? true;

    // New feature B: Code Shredder window
    _otpShredMinutes = prefs.getInt('otpShredMinutes') ?? 0;

    // Photo vault
    _capturePhotos = prefs.getBool('capturePhotos') ?? true;

    // New feature: multi-language support
    final localeCode = prefs.getString('appLocaleCode');
    _appLocale = localeCode != null ? Locale(localeCode) : null;

    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', _themeModeToString(mode));
  }

  // ─── Quiet Hours Methods ───
  Future<void> setQuietHoursEnabled(bool enabled) async {
    _quietHoursEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('quietHoursEnabled', enabled);
  }

  Future<void> setQuietHoursStart(TimeOfDay time) async {
    _quietHoursStart = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quietHoursStartHour', time.hour);
    await prefs.setInt('quietHoursStartMinute', time.minute);
  }

  Future<void> setQuietHoursEnd(TimeOfDay time) async {
    _quietHoursEnd = time;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('quietHoursEndHour', time.hour);
    await prefs.setInt('quietHoursEndMinute', time.minute);
  }

  // ─── Search History Methods ───
  Future<void> addSearchQuery(String query) async {
    if (query.trim().isEmpty) return;
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    if (_searchHistory.length > _maxSearchHistory) {
      _searchHistory = _searchHistory.sublist(0, _maxSearchHistory);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('searchHistory', _searchHistory);
  }

  Future<void> removeSearchQuery(String query) async {
    _searchHistory.remove(query);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('searchHistory', _searchHistory);
  }

  Future<void> clearSearchHistory() async {
    _searchHistory.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('searchHistory', _searchHistory);
  }

  // ─── Merged from base.apk (com.example.fluter): Data Hygiene / retention ───
  /// Persists locally. The caller is also responsible for calling
  /// [NotificationRepository.setRetentionDays] so the native RetentionWorker
  /// picks up the change (see settings_screen.dart, matching the existing
  /// Quiet Hours pattern of provider-persists + repo-pushes-to-native).
  Future<void> setRetentionDays(int days) async {
    _retentionDays = days;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('retentionDays', days);
  }

  // ─── Merged from base.apk (com.example.fluter): Keyword Radar ───
  Future<void> addPriorityKeyword(String keyword) async {
    final kb = keyword.trim();
    if (kb.isEmpty || _priorityKeywords.contains(kb)) return;
    _priorityKeywords.add(kb);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('priorityKeywords', _priorityKeywords);
  }

  Future<void> removePriorityKeyword(String keyword) async {
    _priorityKeywords.remove(keyword);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('priorityKeywords', _priorityKeywords);
  }

  // ─── Merged from base.apk (com.example.fluter): Biometric Vault lock ───
  Future<void> setBiometricLockEnabled(bool enabled) async {
    _biometricLockEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometricLockEnabled', enabled);
  }

  // ─── New feature: instant local alerts. Local persistence only - the caller
  // (settings_screen.dart) is also responsible for calling
  // NotificationRepository.setInstantAlertsEnabled so the native listener picks
  // it up, matching the existing retention/keyword pattern. ───
  Future<void> setInstantAlertsEnabled(bool enabled) async {
    _instantAlertsEnabled = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('instantAlertsEnabled', enabled);
  }

  // ─── New feature B: Code Shredder. Local persistence only - the caller
  // (settings_screen.dart) is also responsible for calling
  // NotificationRepository.setOtpShredMinutes so the native shred worker picks
  // it up, matching the existing retention/keyword/alert pattern. ───
  Future<void> setOtpShredMinutes(int minutes) async {
    _otpShredMinutes = minutes;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('otpShredMinutes', minutes);
  }

  // ─── Photo vault. Local persistence only - the caller also pushes the
  // value to the native listener through NotificationRepository.setCapturePhotos,
  // matching the other settings that the listener reads. ───
  Future<void> setCapturePhotos(bool enabled) async {
    _capturePhotos = enabled;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('capturePhotos', enabled);
  }

  ThemeMode _themeModeFromString(String str) {
    switch (str) {
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      case 'dark':
      default:
        return ThemeMode.dark;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
      case ThemeMode.dark:
        return 'dark';
    }
  }
}
