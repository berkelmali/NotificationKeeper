class AppInfoModel {
  final String packageName;
  final String appName;
  final bool isMonitored;
  final int notificationCount;
  final DateTime? snoozedUntil; // New feature: per-app temporary snooze

  /// App detection: preinstalled system package (not updated from a store).
  final bool isSystem;

  /// App detection: has a launcher icon, i.e. what a person thinks of as an app.
  final bool isLaunchable;

  AppInfoModel({
    required this.packageName,
    required this.appName,
    required this.isMonitored,
    this.notificationCount = 0,
    this.snoozedUntil,
    this.isSystem = false,
    this.isLaunchable = true,
  });

  bool get isSnoozed => snoozedUntil != null && snoozedUntil!.isAfter(DateTime.now());

  AppInfoModel copyWith({bool? isMonitored, DateTime? snoozedUntil, bool clearSnooze = false}) {
    return AppInfoModel(
      packageName: packageName,
      appName: appName,
      isMonitored: isMonitored ?? this.isMonitored,
      notificationCount: notificationCount,
      snoozedUntil: clearSnooze ? null : (snoozedUntil ?? this.snoozedUntil),
      isSystem: isSystem,
      isLaunchable: isLaunchable,
    );
  }

  factory AppInfoModel.fromMap(Map<Object?, Object?> map) {
    final snoozeRaw = map['snoozedUntil'] as num?;
    return AppInfoModel(
      packageName: map['packageName'] as String,
      appName: map['appName'] as String,
      isMonitored: map['isMonitored'] == 1 || map['isMonitored'] == true,
      notificationCount: (map['notificationCount'] as num?)?.toInt() ?? 0,
      snoozedUntil: snoozeRaw != null ? DateTime.fromMillisecondsSinceEpoch(snoozeRaw.toInt()) : null,
      isSystem: map['isSystem'] == true,
      isLaunchable: map['isLaunchable'] != false,
    );
  }
}
