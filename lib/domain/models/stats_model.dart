import '../apps/known_apps.dart';

class StatsModel {
  final int totalCount;
  final int todayCount;
  final int weekCount;
  final Map<String, int> appCounts; // packageName -> count
  final List<DailyCount> dailyCounts; // last 7 days
  final Map<int, int> hourlyCounts; // hour (0-23) -> count (for heatmap)

  // ─── Merged from base.apk (com.example.fluter) ───
  final int otpCountToday;
  final int priorityCountToday;
  /// Notifications captured quietly (stored, alert withheld) during Quiet Hours today.
  final int quietHoursSkippedToday;

  /// New feature A: messages withdrawn by their sender today.
  final int recalledTodayCount;

  StatsModel({
    required this.totalCount,
    required this.todayCount,
    required this.weekCount,
    required this.appCounts,
    required this.dailyCounts,
    this.hourlyCounts = const {},
    this.otpCountToday = 0,
    this.priorityCountToday = 0,
    this.quietHoursSkippedToday = 0,
    this.recalledTodayCount = 0,
  });

  String get topApp {
    if (appCounts.isEmpty) return 'None';
    final sorted = appCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    // Same naming as the rest of the UI: the verified known-app table, then a
    // readable guess. (This was a fifth copy of the last-segment guesser that
    // called Telegram "Messenger".)
    return KnownApps.labelFor(sorted.first.key);
  }

  int get topAppCount {
    if (appCounts.isEmpty) return 0;
    final sorted = appCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.value;
  }

  List<MapEntry<String, int>> get topApps {
    final sorted = appCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }
}

class DailyCount {
  final DateTime date;
  final int count;

  DailyCount({required this.date, required this.count});
}
