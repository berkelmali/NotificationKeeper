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
        case 'deleteNotification':
          return true;
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

  group('Real undo', () {
    // The old Undo re-fetched after the row was already gone natively, so it
    // could never bring anything back.
    int deleteCalls() => calledMethods.where((m) => m == 'deleteNotification').length;

    test('a delete leaves the list at once but not the database', () async {
      final provider = NotificationProvider();
      await provider.fetchNotifications();

      provider.deleteWithUndo(3);

      expect(provider.notifications.map((n) => n.id), isNot(contains(3)));
      expect(provider.isPendingDelete(3), isTrue);
      expect(deleteCalls(), 0);
      provider.dispose();
    });

    test('undo puts it back where it was, and nothing reaches the database', () async {
      final provider = NotificationProvider();
      await provider.fetchNotifications();
      final before = provider.notifications.map((n) => n.id).toList();

      provider.deleteWithUndo(3);
      final restored = provider.undoDelete(3);

      expect(restored, isTrue);
      expect(provider.notifications.map((n) => n.id).toList(), before);
      expect(deleteCalls(), 0);
      provider.dispose();
    });

    test('undo after the window has closed reports false', () async {
      final provider = NotificationProvider();
      await provider.fetchNotifications();
      provider.deleteWithUndo(3);
      await provider.flushPendingDeletes();

      expect(provider.undoDelete(3), isFalse);
      provider.dispose();
    });

    test('going to the background commits pending deletes immediately', () async {
      final provider = NotificationProvider();
      await provider.fetchNotifications();
      provider.deleteWithUndo(2);
      provider.deleteWithUndo(4);

      await provider.flushPendingDeletes();

      expect(deleteCalls(), 2);
      expect(provider.isPendingDelete(2), isFalse);
      provider.dispose();
    });

    testWidgets('the delete reaches the database once the undo window closes', (tester) async {
      final provider = NotificationProvider();
      await tester.runAsync(() => provider.fetchNotifications());
      provider.deleteWithUndo(1);

      await tester.pump(NotificationProvider.undoWindow - const Duration(milliseconds: 100));
      expect(deleteCalls(), 0);

      await tester.pump(const Duration(milliseconds: 200));
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 10)));
      expect(deleteCalls(), 1);
      provider.dispose();
    });

    test('a reload during the window does not bring the deleted row back', () async {
      final provider = NotificationProvider();
      await provider.fetchNotifications();
      provider.deleteWithUndo(5);

      await provider.fetchNotifications(silent: true);

      expect(provider.notifications.map((n) => n.id), isNot(contains(5)));
      provider.dispose();
    });
  });

  group('Live refresh', () {
    test('a silent reload never flips the loading state', () async {
      final provider = NotificationProvider();
      await provider.fetchNotifications();
      final states = <bool>[];
      provider.addListener(() => states.add(provider.isLoading));

      await provider.fetchNotifications(silent: true);

      expect(states, isNot(contains(true)));
      provider.dispose();
    });
  });
}
