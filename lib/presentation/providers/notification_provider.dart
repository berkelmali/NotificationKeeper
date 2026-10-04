import 'package:flutter/material.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/models/notification_model.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();
  List<NotificationModel> _allNotifications = [];
  List<NotificationModel> _filteredNotifications = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedApp;
  String _filterMode = 'all'; // all, starred, unread, tagged, recalled, photos
  String? _selectedTag;

  // New feature: date-range filtering (complements text search)
  DateTimeRange? _dateRange;

  List<NotificationModel> get notifications => _filteredNotifications;
  List<NotificationModel> get allNotifications => _allNotifications;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedApp => _selectedApp;
  String get filterMode => _filterMode;
  String? get selectedTag => _selectedTag;
  DateTimeRange? get dateRange => _dateRange;

  void setDateRange(DateTimeRange? range) {
    _dateRange = range;
    _applyFilters();
    notifyListeners();
  }

  /// Get unique app names from notifications
  List<String> get uniqueApps {
    final apps = _allNotifications.map((n) => n.packageName).toSet().toList();
    apps.sort();
    return apps;
  }

  /// Feature 3: Get all unique tags across all notifications
  List<String> get allTags {
    final tags = <String>{};
    for (var n in _allNotifications) {
      tags.addAll(n.tagList);
    }
    final sorted = tags.toList()..sort();
    return sorted;
  }

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();
    try {
      // New feature B: shred anything that expired since the last worker tick
      // *before* reading, so an out-of-date code is never drawn on screen even
      // for a frame. Cheap no-op while the shredder is off, and never allowed
      // to take the archive down with it if the platform call fails.
      try {
        await _repository.shredExpiredCodesNow();
      } catch (e) {
        debugPrint("Shred pass skipped: $e");
      }
      _allNotifications = await _repository.getAllNotifications();
      _applyFilters();
    } catch (e) {
      debugPrint("Error fetching notifications: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String query) {
    _searchQuery = query;
    _applyFilters();
    notifyListeners();
  }

  void filterByApp(String? packageName) {
    _selectedApp = packageName;
    _applyFilters();
    notifyListeners();
  }

  void setFilterMode(String mode) {
    _filterMode = mode;
    _applyFilters();
    notifyListeners();
  }

  /// Feature 3: Filter by tag
  void filterByTag(String? tag) {
    _selectedTag = tag;
    _applyFilters();
    notifyListeners();
  }

  Future<void> deleteNotification(int id) async {
    final success = await _repository.deleteNotification(id);
    if (success) {
      _allNotifications.removeWhere((n) => n.id == id);
      _applyFilters();
      notifyListeners();
    }
  }

  Future<void> toggleStar(int id) async {
    final index = _allNotifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final notification = _allNotifications[index];
      final newStarred = !notification.isStarred;
      
      // Optimistic update
      _allNotifications[index] = notification.copyWith(isStarred: newStarred);
      _applyFilters();
      notifyListeners();
      
      final success = await _repository.toggleStar(id, newStarred);
      if (!success) {
        // Revert
        _allNotifications[index] = notification;
        _applyFilters();
        notifyListeners();
      }
    }
  }

  Future<void> markAsRead(int id) async {
    final index = _allNotifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final notification = _allNotifications[index];
      _allNotifications[index] = notification.copyWith(isRead: true);
      _applyFilters();
      notifyListeners();
      await _repository.markAsRead(id);
    }
  }

  /// Feature 3: Update tags for a notification
  Future<void> updateTags(int id, List<String> tags) async {
    final index = _allNotifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final tagStr = tags.join(',');
      // Optimistic update
      _allNotifications[index] = _allNotifications[index].copyWith(tags: tagStr);
      _applyFilters();
      notifyListeners();
      
      await _repository.updateTags(id, tagStr);
    }
  }

  /// Feature 3: Add a tag to a notification
  Future<void> addTag(int id, String tag) async {
    final index = _allNotifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final currentTags = _allNotifications[index].tagList;
      if (!currentTags.contains(tag)) {
        currentTags.add(tag);
        await updateTags(id, currentTags);
      }
    }
  }

  /// Feature 3: Remove a tag from a notification
  Future<void> removeTag(int id, String tag) async {
    final index = _allNotifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final currentTags = _allNotifications[index].tagList;
      currentTags.remove(tag);
      await updateTags(id, currentTags);
    }
  }

  void _applyFilters() {
    var filtered = List<NotificationModel>.from(_allNotifications);

    // Filter by app
    if (_selectedApp != null) {
      filtered = filtered.where((n) => n.packageName == _selectedApp).toList();
    }

    // Filter by mode
    if (_filterMode == 'starred') {
      filtered = filtered.where((n) => n.isStarred).toList();
    } else if (_filterMode == 'unread') {
      filtered = filtered.where((n) => !n.isRead).toList();
    } else if (_filterMode == 'tagged') {
      filtered = filtered.where((n) => n.tagList.isNotEmpty).toList();
    } else if (_filterMode == 'recalled') {
      // New feature A: only messages their sender tried to take back
      filtered = filtered.where((n) => n.isRecalled).toList();
    } else if (_filterMode == 'photos') {
      // Photo vault: only notifications that carried a picture
      filtered = filtered.where((n) => n.hasImage).toList();
    }

    // Filter by specific tag
    if (_selectedTag != null) {
      filtered = filtered.where((n) => n.tagList.contains(_selectedTag)).toList();
    }

    // New feature: filter by date range
    if (_dateRange != null) {
      final startMillis = _dateRange!.start.millisecondsSinceEpoch;
      // Add a day minus 1ms so the end date is inclusive of the whole day
      final endMillis = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day, 23, 59, 59, 999)
          .millisecondsSinceEpoch;
      filtered = filtered.where((n) => n.timestamp >= startMillis && n.timestamp <= endMillis).toList();
    }

    // Search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((n) {
        final title = n.title?.toLowerCase() ?? '';
        final content = n.content?.toLowerCase() ?? '';
        final pkg = n.packageName.toLowerCase();
        final tags = n.tags?.toLowerCase() ?? '';
        final q = _searchQuery.toLowerCase();
        return title.contains(q) || content.contains(q) || pkg.contains(q) || tags.contains(q);
      }).toList();
    }

    // Sort by timestamp desc
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    _filteredNotifications = filtered;
  }
}
