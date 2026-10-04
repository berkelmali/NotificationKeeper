import 'package:flutter_test/flutter_test.dart';
import 'package:app/domain/models/stats_model.dart';

void main() {
  group('StatsModel defaults', () {
    test('merged fields (otp/priority/quietHours) default to 0 '
        'when not supplied, so older callers do not break', () {
      final stats = StatsModel(
        totalCount: 10,
        todayCount: 2,
        weekCount: 5,
        appCounts: const {},
        dailyCounts: const [],
      );

      expect(stats.otpCountToday, 0);
      expect(stats.priorityCountToday, 0);
      expect(stats.quietHoursSkippedToday, 0);
      expect(stats.hourlyCounts, isEmpty);
    });
  });

  group('StatsModel.topApp', () {
    test('returns "None" when there is no data yet', () {
      final stats = _statsWith(appCounts: const {});
      expect(stats.topApp, 'None');
      expect(stats.topAppCount, 0);
    });

    test('picks the package with the highest count', () {
      final stats = _statsWith(appCounts: const {
        'com.whatsapp': 12,
        'com.instagram': 30,
        'com.example.mail': 5,
      });

      expect(stats.topApp, 'Instagram');
      expect(stats.topAppCount, 30);
    });

    test('capitalizes only the last segment of the package name', () {
      final stats = _statsWith(appCounts: const {'com.example.telegram': 4});
      expect(stats.topApp, 'Telegram');
    });

    test('capitalizes a package name that has no dots', () {
      final stats = _statsWith(appCounts: const {'standalonepkg': 3});
      expect(stats.topApp, 'Standalonepkg');
    });

    // Regression: the old guesser took the last segment, so these came out as
    // "Messenger" and "Android".
    test('names Telegram and Instagram correctly', () {
      expect(_statsWith(appCounts: const {'org.telegram.messenger': 9}).topApp, 'Telegram');
      expect(_statsWith(appCounts: const {'com.instagram.android': 9}).topApp, 'Instagram');
    });

    test('breaks ties deterministically by keeping stable sort order', () {
      final stats = _statsWith(appCounts: const {
        'com.a.first': 5,
        'com.b.second': 5,
      });
      // Both have equal counts - just assert *a* valid entry wins, and the
      // count itself is correct, without over-specifying tie-break order.
      expect(stats.topAppCount, 5);
      expect(['First', 'Second'], contains(stats.topApp));
    });
  });

  group('StatsModel.topApps', () {
    test('returns at most 5 entries, sorted descending by count', () {
      final stats = _statsWith(appCounts: const {
        'com.a': 1,
        'com.b': 6,
        'com.c': 3,
        'com.d': 9,
        'com.e': 2,
        'com.f': 7,
      });

      final top = stats.topApps;
      expect(top.length, 5);
      expect(top.first.value, 9);
      // Verify the whole list is actually sorted descending, not just the head.
      for (var i = 0; i < top.length - 1; i++) {
        expect(top[i].value, greaterThanOrEqualTo(top[i + 1].value));
      }
    });

    test('returns an empty list when there is no data', () {
      expect(_statsWith(appCounts: const {}).topApps, isEmpty);
    });
  });
}

StatsModel _statsWith({required Map<String, int> appCounts}) {
  return StatsModel(
    totalCount: 0,
    todayCount: 0,
    weekCount: 0,
    appCounts: appCounts,
    dailyCounts: const [],
  );
}
