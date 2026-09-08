import 'package:flutter/foundation.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/models/stats_model.dart';

/// Dashboard statistics.
///
/// This used to carry its own `AppStats` and `DailyCount` classes plus a second,
/// independent `MethodChannel` call to `getStats` - a parallel copy of
/// [StatsModel] and [NotificationRepository.getStats]. The two drifted apart the
/// moment a field was added to only one of them (see the `recalledTodayCount`
/// build break), so the duplicate has been removed: this provider now goes
/// through the repository like every other provider in the app, and [StatsModel]
/// is the single definition of what a stats payload contains.
class StatsProvider with ChangeNotifier {
  final NotificationRepository _repository = NotificationRepository();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StatsModel? _stats;
  StatsModel? get stats => _stats;

  List<int> _hourlyActivity = List.filled(24, 0);
  List<int> get hourlyActivity => _hourlyActivity;

  int _peakHour = 0;
  int get peakHour => _peakHour;

  Future<void> fetchStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      _stats = await _repository.getStats();
      _updateHourlyData();
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
