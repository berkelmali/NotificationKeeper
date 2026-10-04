import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/presentation/providers/notification_provider.dart';

/// Covers the archive filtering rules, with an emphasis on the Recall Radar
/// filter added with new feature A. The native side is faked so these run on a
/// plain `flutter test` with no device attached.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.example.notification_keeper/notifications');
  late List<String> calledMethods;

  Map<String, Object?> row({
    required int id,
    String packageName = 'com.whatsapp',
    String? title,
    String? content,
    int timestamp = 1700000000000,
    bool isStarred = false,
    bool isRead = true,
    String? tags,
    int? recalledAt,
    bool codeShredded = false,
    String? imagePath,
  }) {
    return {
      'id': id,
      'packageName': packageName,
      'title': title ?? 'Title $id',
      'content': content ?? 'Body $id',
      'subText': null,
      'timestamp': timestamp,
      'category': 'msg',
      'groupKey': null,
      'isGroupSummary': false,
      'messagingUser': null,
      'isRead': isRead,
      'isStarred': isStarred,
      'tags': tags,
      'isOtp': false,
      'extractedCode': null,
      'isPriorityFlagged': false,
      'imagePath': imagePath,
      'recalledAt': recalledAt,
      'codeShredded': codeShredded,
    };
  }

  late List<Map<String, Object?>> stored;

  setUp(() {
    calledMethods = [];
    // Distinct timestamps so the "newest first" ordering the provider applies
    // is unambiguous and these expectations don't depend on sort stability.
    stored = [
      row(id: 1, title: 'Plain', timestamp: 1700000001000),
      row(id: 2, title: 'Withdrawn', timestamp: 1700000002000, recalledAt: 1700000005000),
      row(id: 3, title: 'Starred', timestamp: 1700000003000, isStarred: true),
      row(id: 4, title: 'Also withdrawn', timestamp: 1700000004000, recalledAt: 1700000009000),
      row(id: 5, title: 'Unread', timestamp: 1700000005000, isRead: false),
    ];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      calledMethods.add(call.method);
      switch (call.method) {
        case 'shredExpiredCodesNow':
          return 0;
        case 'getAllNotifications':
          return stored;
        default:
          throw MissingPluginException('Unmocked method: ${call.method}');
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('Recall Radar filter (new feature A)', () {
    test('the default "all" mode shows withdrawn notifications alongside the rest',
        () async {
      final provider = NotificationProvider();
      await provider.fetchNotifications();

      expect(provider.notifications.length, 5);
    });

    test('the "recalled" mode keeps only notifications their sender took back',
        () async {
      final provider = NotificationProvider();
      await provider.fetchNotifications();

      provider.setFilterMode('recalled');

      expect(provider.notifications.map((n) => n.id), [4, 2]);
      expect(provider.notifications.every((n) => n.isRecalled), true);
    });

    test('switching back to "all" restores the full list', () async {
      final provider = NotificationProvider();
      await provider.fetchNotifications();

      provider.setFilterMode('recalled');
      provider.setFilterMode('all');

      expect(provider.notifications.length, 5);
    });

    test('the recalled filter composes with the text search', () async {
      final provider = NotificationProvider();
      await provider.fetchNotifications();

      provider.setFilterMode('recalled');
      provider.search('also');

      expect(provider.notifications.map((n) => n.id), [4]);
    });

    test('yields an empty list rather than everything when nothing was recalled',
        () async {
      stored = [row(id: 1), row(id: 2)];
      final provider = NotificationProvider();
      await provider.fetchNotifications();

      provider.setFilterMode('recalled');

      expect(provider.notifications, isEmpty);
    });
  });

  group('Photo vault filter', () {
    test('the "photos" mode keeps only notifications that carried a picture', () async {
      stored = [
        row(id: 1, timestamp: 1700000001000),
        row(id: 2, timestamp: 1700000002000, imagePath: '/data/photos/a.jpg'),
        row(id: 3, timestamp: 1700000003000, imagePath: '/data/photos/b.jpg', recalledAt: 1700000009000),
      ];
      final provider = NotificationProvider();
      await provider.fetchNotifications();

      provider.setFilterMode('photos');

      expect(provider.notifications.map((n) => n.id), [3, 2]);
    });

    test('a photo the sender deleted is still listed, with its recall flag', () async {
      stored = [row(id: 9, imagePath: '/data/photos/c.jpg', recalledAt: 1700000009000)];
      final provider = NotificationProvider();
      await provider.fetchNotifications();

      provider.setFilterMode('photos');

      final kept = provider.notifications.single;
      expect(kept.hasImage, true);
      expect(kept.isRecalled, true);
    });
  });

  group('Code Shredder hook (new feature B)', () {
    test('a refresh runs the shred pass before reading the archive, so an '
        'expired code can never be drawn even once', () async {
      final provider = NotificationProvider();
      await provider.fetchNotifications();

      expect(calledMethods, contains('shredExpiredCodesNow'));
      expect(
        calledMethods.indexOf('shredExpiredCodesNow'),
        lessThan(calledMethods.indexOf('getAllNotifications')),
      );
    });

    test('a failing shred pass must not stop the archive from loading', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall call) async {
        if (call.method == 'shredExpiredCodesNow') {
          throw MissingPluginException('native side unavailable');
        }
        if (call.method == 'getAllNotifications') return stored;
        return null;
      });

      final provider = NotificationProvider();
      await provider.fetchNotifications();

      expect(provider.notifications.length, 5);
    });
  });
}
