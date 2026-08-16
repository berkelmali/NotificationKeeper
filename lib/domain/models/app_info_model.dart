class AppInfoModel {
  final String packageName;
  final String appName;
  final bool isMonitored;
  final int notificationCount;
  final DateTime? snoozedUntil; // New feature: per-app temporary snooze

  AppInfoModel({
    required this.packageName,
    required this.appName,
    required this.isMonitored,
    this.notificationCount = 0,
    this.snoozedUntil,
  });

  bool get isSnoozed => snoozedUntil != null && snoozedUntil!.isAfter(DateTime.now());

  factory AppInfoModel.fromMap(Map<Object?, Object?> map) {
    final snoozeRaw = map['snoozedUntil'] as num?;
    return AppInfoModel(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      isMonitored: map['isMonitored'] == 1 || map['isMonitored'] == true,
      notificationCount: (map['notificationCount'] as num?)?.toInt() ?? 0,
      snoozedUntil: snoozeRaw != null ? DateTime.fromMillisecondsSinceEpoch(snoozeRaw.toInt()) : null,
    );
  }
}
