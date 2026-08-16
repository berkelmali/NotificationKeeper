import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../../domain/models/notification_model.dart';

class DailyCount {
  final DateTime date;
  final int count;
  DailyCount({required this.date, required this.count});
}

class AppStats {
  final int totalCount;
  final int todayCount;
  final int weekCount;
  final int otpCountToday;
  final int priorityCountToday;
  final int quietHoursSkippedToday;
  final Map<String, int> appCounts;
  final List<DailyCount> dailyCounts;
  final Map<int, int> hourlyCounts;

  AppStats({
    required this.totalCount,
    required this.todayCount,
    required this.weekCount,
    required this.otpCountToday,
    required this.priorityCountToday,
    required this.quietHoursSkippedToday,
    required this.appCounts,
    required this.dailyCounts,
    required this.hourlyCounts,
  });

  List<MapEntry<String, int>> get topApps {
    final list = appCounts.entries.toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }
}

class StatsProvider with ChangeNotifier {
  static const _channel = MethodChannel('com.example.notification_keeper/notifications');

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  AppStats? _stats;
  AppStats? get stats => _stats;

  List<int> _hourlyActivity = List.filled(24, 0);
  List<int> get hourlyActivity => _hourlyActivity;

  int _peakHour = 0;
  int get peakHour => _peakHour;

  Future<void> fetchStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _channel.invokeMethod('getStats');
      if (result != null && result is Map) {
        final rawAppCounts = result['appCounts'] as Map?;
        final appCountsMap = <String, int>{};
        if (rawAppCounts != null) {
          rawAppCounts.forEach((key, value) {
            appCountsMap[key.toString()] = (value as num).toInt();
          });
        }

        final rawDaily = result['dailyCounts'] as List?;
        final dailyList = <DailyCount>[];
        if (rawDaily != null) {
          for (var item in rawDaily) {
            if (item is Map) {
              final ms = (item['date'] as num?)?.toInt() ?? 0;
              final count = (item['count'] as num?)?.toInt() ?? 0;
              dailyList.add(DailyCount(
                date: DateTime.fromMillisecondsSinceEpoch(ms),
                count: count,
              ));
            }
          }
        }

        final rawHourly = result['hourlyCounts'] as Map?;
        final hourlyMap = <int, int>{};
        if (rawHourly != null) {
          rawHourly.forEach((key, value) {
            final h = int.tryParse(key.toString()) ?? 0;
            hourlyMap[h] = (value as num).toInt();
          });
        }

        _stats = AppStats(
          totalCount: (result['totalCount'] as num?)?.toInt() ?? 0,
          todayCount: (result['todayCount'] as num?)?.toInt() ?? 0,
          weekCount: (result['weekCount'] as num?)?.toInt() ?? 0,
          otpCountToday: (result['otpCountToday'] as num?)?.toInt() ?? 0,
          priorityCountToday: (result['priorityCountToday'] as num?)?.toInt() ?? 0,
          quietHoursSkippedToday: (result['quietHoursSkippedToday'] as num?)?.toInt() ?? 0,
          appCounts: appCountsMap,
          dailyCounts: dailyList,
          hourlyCounts: hourlyMap,
        );

        _updateHourlyData();
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void computeHourlyFromNotifications(List<NotificationModel> notifications) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

    final counts = List<int>.filled(24, 0);
    for (var n in notifications) {
      if (n.timestamp >= todayStart) {
        final dt = DateTime.fromMillisecondsSinceEpoch(n.timestamp);
        counts[dt.hour] += 1;
      }
    }

    _hourlyActivity = counts;
    _calcPeakHour();
    notifyListeners();
  }

  void _updateHourlyData() {
    if (_stats != null && _stats!.hourlyCounts.isNotEmpty) {
      final counts = List<int>.filled(24, 0);
      _stats!.hourlyCounts.forEach((hour, count) {
        if (hour >= 0 && hour < 24) {
          counts[hour] = count;
        }
      });
      _hourlyActivity = counts;
      _calcPeakHour();
    }
  }

  void _calcPeakHour() {
    int maxHour = 0;
    int maxCount = -1;
    for (int i = 0; i < 24; i++) {
      if (_hourlyActivity[i] > maxCount) {
        maxCount = _hourlyActivity[i];
        maxHour = i;
      }
    }
    _peakHour = maxHour;
  }
}
