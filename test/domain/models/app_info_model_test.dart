import 'package:flutter_test/flutter_test.dart';
import 'package:app/domain/models/app_info_model.dart';

void main() {
  group('AppInfoModel.isSnoozed', () {
    test('is false when snoozedUntil is null', () {
      final app = AppInfoModel(
        packageName: 'com.example',
        appName: 'Example',
        isMonitored: true,
      );
      expect(app.isSnoozed, false);
    });

    test('is true when snoozedUntil is in the future', () {
      final app = AppInfoModel(
        packageName: 'com.example',
        appName: 'Example',
        isMonitored: true,
        snoozedUntil: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(app.isSnoozed, true);
    });

    test('is false when snoozedUntil is in the past '
        '(a stale snooze that should be treated as expired)', () {
      final app = AppInfoModel(
        packageName: 'com.example',
        appName: 'Example',
        isMonitored: true,
        snoozedUntil: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(app.isSnoozed, false);
    });

    test('is false at the exact snooze boundary (isAfter is strict)', () {
      final now = DateTime.now();
      final app = AppInfoModel(
        packageName: 'com.example',
        appName: 'Example',
        isMonitored: true,
        snoozedUntil: now,
      );
      // snoozedUntil == "now" captured a few microseconds ago, so by the
      // time isSnoozed evaluates DateTime.now() again it will already be
      // slightly after `now` - this documents that behavior rather than
      // asserting a specific edge value.
      expect(app.isSnoozed, false);
    });
  });

  group('AppInfoModel.fromMap', () {
    test('parses snoozedUntil from an epoch-millis number', () {
      final futureMillis =
          DateTime.now().add(const Duration(hours: 8)).millisecondsSinceEpoch;
      final map = <Object?, Object?>{
        'packageName': 'com.example',
        'appName': 'Example',
        'isMonitored': true,
        'notificationCount': 5,
        'snoozedUntil': futureMillis,
      };

      final app = AppInfoModel.fromMap(map);

      expect(app.snoozedUntil, isNotNull);
      expect(app.snoozedUntil!.millisecondsSinceEpoch, futureMillis);
      expect(app.isSnoozed, true);
    });

    test('treats a null snoozedUntil (app never snoozed) correctly', () {
      final map = <Object?, Object?>{
        'packageName': 'com.example',
        'appName': 'Example',
        'isMonitored': false,
        'notificationCount': 0,
        'snoozedUntil': null,
      };

      final app = AppInfoModel.fromMap(map);

      expect(app.snoozedUntil, isNull);
      expect(app.isSnoozed, false);
    });

    test('accepts isMonitored encoded as native int 0/1', () {
      final map = <Object?, Object?>{
        'packageName': 'com.example',
        'appName': 'Example',
        'isMonitored': 1,
        'notificationCount': 0,
      };
      expect(AppInfoModel.fromMap(map).isMonitored, true);
    });

    test('defaults notificationCount to 0 when absent', () {
      final map = <Object?, Object?>{
        'packageName': 'com.example',
        'appName': 'Example',
        'isMonitored': true,
      };
      expect(AppInfoModel.fromMap(map).notificationCount, 0);
    });
  });

  group('App detection flags', () {
    test('parses isSystem and isLaunchable from the native map', () {
      final app = AppInfoModel.fromMap(const {
        'packageName': 'com.android.shell',
        'appName': 'Shell',
        'isMonitored': false,
        'isSystem': true,
        'isLaunchable': false,
      });
      expect(app.isSystem, isTrue);
      expect(app.isLaunchable, isFalse);
    });

    test('treats an app as a launcher app when the flag is missing', () {
      // Older native builds did not send these fields.
      final app = AppInfoModel.fromMap(const {
        'packageName': 'com.whatsapp',
        'appName': 'WhatsApp',
        'isMonitored': true,
      });
      expect(app.isSystem, isFalse);
      expect(app.isLaunchable, isTrue);
    });
  });
}
