import 'package:flutter/material.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/models/app_info_model.dart';

class AppListProvider extends ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();
  List<AppInfoModel> _allApps = [];
  List<AppInfoModel> _filteredApps = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _viewMode = 'all'; // all, monitored, unmonitored

  // App detection: system packages (navigation-bar overlays, shared libraries
  // and the like) are hidden unless asked for.
  bool _showSystemApps = false;
  bool get showSystemApps => _showSystemApps;

  List<AppInfoModel> get apps => _filteredApps;
  List<AppInfoModel> get allApps => _allApps;
  bool get isLoading => _isLoading;
  String get viewMode => _viewMode;
  int get monitoredCount => _allApps.where((a) => a.isMonitored).length;
  int get totalCount => _allApps.length;

  Future<void> fetchApps() async {
    _isLoading = true;
    notifyListeners();
    try {
      _allApps = await _repository.getMonitoredApps(includeSystem: _showSystemApps);
      _applyFilters();
    } catch (e) {
      debugPrint("Error fetching apps: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setShowSystemApps(bool show) async {
    if (_showSystemApps == show) return;
    _showSystemApps = show;
    await fetchApps();
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void setViewMode(String mode) {
    _viewMode = mode;
    _applyFilters();
    notifyListeners();
  }

  Future<void> toggleApp(String packageName, bool isMonitored) async {
    // Optimistic update
    final index = _allApps.indexWhere((app) => app.packageName == packageName);
    if (index != -1) {
      final oldApp = _allApps[index];
      _allApps[index] = AppInfoModel(
        packageName: oldApp.packageName,
        appName: oldApp.appName,
        isMonitored: isMonitored,
        notificationCount: oldApp.notificationCount,
        snoozedUntil: oldApp.snoozedUntil,
      );
      _applyFilters();
      notifyListeners();
    }

    final success = await _repository.toggleAppMonitoring(packageName, isMonitored);
    if (!success && index != -1) {
      // Revert if failed
      final oldApp = _allApps[index];
      _allApps[index] = AppInfoModel(
        packageName: oldApp.packageName,
        appName: oldApp.appName,
        isMonitored: !isMonitored,
        notificationCount: oldApp.notificationCount,
        snoozedUntil: oldApp.snoozedUntil,
      );
      _applyFilters();
      notifyListeners();
    }
  }

  // ─── New feature: per-app temporary snooze ───
  Future<void> snoozeApp(String packageName, int minutes) async {
    final success = await _repository.snoozeApp(packageName, minutes);
    if (success) {
      final index = _allApps.indexWhere((app) => app.packageName == packageName);
      if (index != -1) {
        final oldApp = _allApps[index];
        _allApps[index] = AppInfoModel(
          packageName: oldApp.packageName,
          appName: oldApp.appName,
          isMonitored: oldApp.isMonitored,
          notificationCount: oldApp.notificationCount,
          snoozedUntil: DateTime.now().add(Duration(minutes: minutes)),
        );
        _applyFilters();
        notifyListeners();
      }
    }
  }

  Future<void> unsnoozeApp(String packageName) async {
    final success = await _repository.unsnoozeApp(packageName);
    if (success) {
      final index = _allApps.indexWhere((app) => app.packageName == packageName);
      if (index != -1) {
        final oldApp = _allApps[index];
        _allApps[index] = AppInfoModel(
          packageName: oldApp.packageName,
          appName: oldApp.appName,
          isMonitored: oldApp.isMonitored,
          notificationCount: oldApp.notificationCount,
          snoozedUntil: null,
        );
        _applyFilters();
        notifyListeners();
      }
    }
  }

  Future<void> setAllMonitored(bool isMonitored) async {
    for (var i = 0; i < _allApps.length; i++) {
      final app = _allApps[i];
      if (app.isMonitored != isMonitored) {
        _allApps[i] = AppInfoModel(
          packageName: app.packageName,
          appName: app.appName,
          isMonitored: isMonitored,
          notificationCount: app.notificationCount,
          snoozedUntil: app.snoozedUntil,
        );
        // Fire and forget
        _repository.toggleAppMonitoring(app.packageName, isMonitored);
      }
    }
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    var filtered = List<AppInfoModel>.from(_allApps);

    // Filter by mode
    if (_viewMode == 'monitored') {
      filtered = filtered.where((a) => a.isMonitored).toList();
    } else if (_viewMode == 'unmonitored') {
      filtered = filtered.where((a) => !a.isMonitored).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((a) {
        return a.appName.toLowerCase().contains(q) ||
            a.packageName.toLowerCase().contains(q);
      }).toList();
    }

    _filteredApps = filtered;
  }
}
