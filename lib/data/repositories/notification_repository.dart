import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/models/app_info_model.dart';
import '../../domain/models/stats_model.dart';

class NotificationRepository {
  static const platform = MethodChannel('com.example.notification_keeper/notifications');

  Future<List<NotificationModel>> getAllNotifications() async {
    try {
      final List<dynamic>? result = await platform.invokeListMethod('getAllNotifications');
      if (result == null) return [];
      return result.map((e) => NotificationModel.fromMap(e as Map<Object?, Object?>)).toList();
    } on PlatformException catch (e) {
      debugPrint("Failed to get notifications: '${e.message}'.");
      return [];
    }
  }

  Future<List<NotificationModel>> getNotificationsByApp(String packageName) async {
    try {
      final List<dynamic>? result = await platform.invokeListMethod('getNotificationsByApp', {
        'packageName': packageName,
      });
      if (result == null) return [];
      return result.map((e) => NotificationModel.fromMap(e as Map<Object?, Object?>)).toList();
    } on PlatformException catch (e) {
      debugPrint("Failed to get notifications by app: '${e.message}'.");
      return [];
    }
  }

  Future<StatsModel> getStats() async {
    try {
      final Map<dynamic, dynamic>? result = await platform.invokeMapMethod('getStats');
      if (result == null) {
        return StatsModel(
          totalCount: 0,
          todayCount: 0,
          weekCount: 0,
          appCounts: {},
          dailyCounts: [],
          hourlyCounts: {},
        );
      }

      final appCountsRaw = result['appCounts'] as Map<dynamic, dynamic>? ?? {};
      final appCounts = appCountsRaw.map(
        (key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 0),
      );

      final dailyCountsRaw = result['dailyCounts'] as List<dynamic>? ?? [];
      final dailyCounts = dailyCountsRaw
          .whereType<Map<dynamic, dynamic>>()
          .map((map) => DailyCount(
                date: DateTime.fromMillisecondsSinceEpoch(
                    (map['date'] as num?)?.toInt() ?? 0),
                count: (map['count'] as num?)?.toInt() ?? 0,
              ))
          .toList();

      // Hourly counts for heatmap. The key arrives as an int from the platform
      // codec, but parse defensively: this is now the only stats path in the app
      // (StatsProvider used to carry a second, more tolerant copy of it), and a
      // cast failure here would blank the whole dashboard rather than one number.
      final hourlyCountsRaw = result['hourlyCounts'] as Map<dynamic, dynamic>? ?? {};
      final hourlyCounts = <int, int>{};
      hourlyCountsRaw.forEach((key, value) {
        final hour = key is num ? key.toInt() : int.tryParse(key.toString());
        if (hour != null) hourlyCounts[hour] = (value as num?)?.toInt() ?? 0;
      });

      return StatsModel(
        totalCount: (result['totalCount'] as num?)?.toInt() ?? 0,
        todayCount: (result['todayCount'] as num?)?.toInt() ?? 0,
        weekCount: (result['weekCount'] as num?)?.toInt() ?? 0,
        appCounts: appCounts,
        dailyCounts: dailyCounts,
        hourlyCounts: hourlyCounts,
        otpCountToday: (result['otpCountToday'] as num?)?.toInt() ?? 0,
        priorityCountToday: (result['priorityCountToday'] as num?)?.toInt() ?? 0,
        quietHoursSkippedToday: (result['quietHoursSkippedToday'] as num?)?.toInt() ?? 0,
        recalledTodayCount: (result['recalledTodayCount'] as num?)?.toInt() ?? 0,
      );
    } on PlatformException catch (e) {
      debugPrint("Failed to get stats: '${e.message}'.");
      return StatsModel(
        totalCount: 0,
        todayCount: 0,
        weekCount: 0,
        appCounts: {},
        dailyCounts: [],
        hourlyCounts: {},
      );
    }
  }

  Future<List<AppInfoModel>> getMonitoredApps() async {
    try {
      final List<dynamic>? result = await platform.invokeListMethod('getMonitoredApps');
      if (result == null) return [];
      return result.map((e) => AppInfoModel.fromMap(e as Map<Object?, Object?>)).toList();
    } on PlatformException catch (e) {
      debugPrint("Failed to get apps: '${e.message}'.");
      return [];
    }
  }

  Future<bool> toggleAppMonitoring(String packageName, bool isMonitored) async {
    try {
      final bool? result = await platform.invokeMethod('toggleAppMonitoring', {
        'packageName': packageName,
        'isMonitored': isMonitored,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to toggle app: '${e.message}'.");
      return false;
    }
  }

  Future<bool> deleteNotification(int id) async {
    try {
      final bool? result = await platform.invokeMethod('deleteNotification', {
        'id': id,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to delete notification: '${e.message}'.");
      return false;
    }
  }

  Future<bool> deleteOlderThan(int days) async {
    try {
      final bool? result = await platform.invokeMethod('deleteOlderThan', {
        'days': days,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to delete old notifications: '${e.message}'.");
      return false;
    }
  }

  Future<bool> deleteAllNotifications() async {
    try {
      final bool? result = await platform.invokeMethod('deleteAllNotifications');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to delete all: '${e.message}'.");
      return false;
    }
  }

  Future<bool> toggleStar(int id, bool isStarred) async {
    try {
      final bool? result = await platform.invokeMethod('toggleStar', {
        'id': id,
        'isStarred': isStarred,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to toggle star: '${e.message}'.");
      return false;
    }
  }

  Future<bool> markAsRead(int id) async {
    try {
      final bool? result = await platform.invokeMethod('markAsRead', {
        'id': id,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to mark as read: '${e.message}'.");
      return false;
    }
  }

  /// Feature 3: Update tags for a notification
  Future<bool> updateTags(int id, String tags) async {
    try {
      final bool? result = await platform.invokeMethod('updateTags', {
        'id': id,
        'tags': tags,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to update tags: '${e.message}'.");
      return false;
    }
  }

  /// Feature 6: Set quiet hours
  Future<bool> setQuietHours(bool enabled, int startHour, int startMinute, int endHour, int endMinute) async {
    try {
      final bool? result = await platform.invokeMethod('setQuietHours', {
        'enabled': enabled,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to set quiet hours: '${e.message}'.");
      return false;
    }
  }

  /// [format] is 'json' (default) or 'csv' - see merge changelog, feature #4
  Future<String?> exportNotifications({String format = 'json'}) async {
    try {
      final String? path = await platform.invokeMethod('exportNotifications', {
        'format': format,
      });
      return path;
    } on PlatformException catch (e) {
      debugPrint("Failed to export: '${e.message}'.");
      return null;
    }
  }

  Future<bool> isServiceEnabled() async {
    try {
      final bool? result = await platform.invokeMethod('isServiceEnabled');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to check service: '${e.message}'.");
      return false;
    }
  }

  Future<void> openNotificationSettings() async {
    try {
      await platform.invokeMethod('openNotificationSettings');
    } on PlatformException catch (e) {
      debugPrint("Failed to open settings: '${e.message}'.");
    }
  }

  // ─── New feature: per-app temporary snooze ───
  Future<bool> snoozeApp(String packageName, int minutes) async {
    try {
      final bool? result = await platform.invokeMethod('snoozeApp', {
        'packageName': packageName,
        'minutes': minutes,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to snooze app: '${e.message}'.");
      return false;
    }
  }

  Future<bool> unsnoozeApp(String packageName) async {
    try {
      final bool? result = await platform.invokeMethod('unsnoozeApp', {
        'packageName': packageName,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to unsnooze app: '${e.message}'.");
      return false;
    }
  }

  // ─── Merged from base.apk (com.example.fluter): Keyword Radar ───

  /// Push the user's priority-keyword list to the native listener.
  Future<bool> updateKeywords(List<String> keywords) async {
    try {
      final bool? result = await platform.invokeMethod('updateKeywords', {
        'keywords': keywords,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to update keywords: '${e.message}'.");
      return false;
    }
  }

  Future<List<String>> getKeywords() async {
    try {
      final List<dynamic>? result = await platform.invokeListMethod('getKeywords');
      return result?.map((e) => e.toString()).toList() ?? [];
    } on PlatformException catch (e) {
      debugPrint("Failed to get keywords: '${e.message}'.");
      return [];
    }
  }

  // ─── Merged from base.apk (com.example.fluter): automatic retention ("Data Hygiene") ───

  /// [days] of 0 disables automatic cleanup (keep forever).
  Future<bool> setRetentionDays(int days) async {
    try {
      final bool? result = await platform.invokeMethod('setRetentionDays', {
        'days': days,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to set retention: '${e.message}'.");
      return false;
    }
  }

  Future<int> getRetentionDays() async {
    try {
      final int? result = await platform.invokeMethod('getRetentionDays');
      return result ?? 0;
    } on PlatformException catch (e) {
      debugPrint("Failed to get retention: '${e.message}'.");
      return 0;
    }
  }

  // ─── New feature: instant local alert when a code/priority match is captured ───
  Future<bool> setInstantAlertsEnabled(bool enabled) async {
    try {
      final bool? result = await platform.invokeMethod('setInstantAlertsEnabled', {
        'enabled': enabled,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint("Failed to set instant alerts: '${e.message}'.");
      return false;
    }
  }

  Future<bool> getInstantAlertsEnabled() async {
    try {
      final bool? result = await platform.invokeMethod('getInstantAlertsEnabled');
      return result ?? true;
    } on PlatformException catch (e) {
      debugPrint("Failed to get instant alerts: '${e.message}'.");
      return true;
    }
  }

  // ─── New feature B: Code Shredder (ephemeral verification codes) ───

  /// [minutes] of 0 keeps captured codes forever (shredder disabled).
  /// Returns how many codes the immediate pass wiped, so the UI can tell the
  /// user that shortening the window took effect right away.
  Future<int> setOtpShredMinutes(int minutes) async {
    try {
      final int? shredded = await platform.invokeMethod('setOtpShredMinutes', {
        'minutes': minutes,
      });
      return shredded ?? 0;
    } on PlatformException catch (e) {
      debugPrint("Failed to set shred window: '${e.message}'.");
      return 0;
    }
  }

  Future<int> getOtpShredMinutes() async {
    try {
      final int? result = await platform.invokeMethod('getOtpShredMinutes');
      return result ?? 0;
    } on PlatformException catch (e) {
      debugPrint("Failed to get shred window: '${e.message}'.");
      return 0;
    }
  }

  /// Runs the shred pass on demand (e.g. when the archive is refreshed), so a
  /// code that expired since the last worker tick is gone before it is drawn.
  Future<int> shredExpiredCodesNow() async {
    try {
      final int? shredded = await platform.invokeMethod('shredExpiredCodesNow');
      return shredded ?? 0;
    } on PlatformException catch (e) {
      debugPrint("Failed to shred codes: '${e.message}'.");
      return 0;
    }
  }

  // ─── New feature #1: date-range aware search ───
  Future<List<NotificationModel>> searchWithDateRange(
    String query,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final List<dynamic>? result = await platform.invokeListMethod('searchWithDateRange', {
        'query': query,
        'start': start.millisecondsSinceEpoch,
        'end': end.millisecondsSinceEpoch,
      });
      if (result == null) return [];
      return result.map((e) => NotificationModel.fromMap(e as Map<Object?, Object?>)).toList();
    } on PlatformException catch (e) {
      debugPrint("Failed to search with date range: '${e.message}'.");
      return [];
    }
  }

  // ─── New feature: restore notifications from a backup file ───
  /// Returns the number of notifications successfully restored.
  Future<int> restoreNotifications(List<Map<String, dynamic>> notifications) async {
    final int? count = await platform.invokeMethod('restoreNotifications', {
      'notifications': notifications,
    });
    return count ?? 0;
  }
}
