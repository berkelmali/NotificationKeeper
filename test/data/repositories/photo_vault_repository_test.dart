import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/repositories/notification_repository.dart';

/// Photo vault: the repository side of keeping pictures from notifications.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PhotoStorageStats.formattedSize', () {
    String size(int bytes) => PhotoStorageStats(count: 1, bytes: bytes).formattedSize;

    test('reports plain bytes below one kilobyte', () {
      expect(size(0), '0 B');
      expect(size(512), '512 B');
    });

    test('shows kilobytes without decimals', () {
      expect(size(1024), '1 KB');
      expect(size(812 * 1024 + 300), '812 KB');
    });

    test('shows one decimal for megabytes and gigabytes under 100', () {
      expect(size((14.3 * 1024 * 1024).round()), '14.3 MB');
      expect(size((1.2 * 1024 * 1024 * 1024).round()), '1.2 GB');
    });

    test('drops the decimal once a value reaches three digits', () {
      expect(size(250 * 1024 * 1024), '250 MB');
    });
  });

  group('NotificationRepository photo vault channel calls', () {
    const channel = MethodChannel('com.example.notification_keeper/notifications');
    late List<MethodCall> calls;

    setUp(() {
      calls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        switch (call.method) {
          case 'getPhotoStorageStats':
            return {'count': 3, 'bytes': 2 * 1024 * 1024};
          case 'getCapturePhotos':
            return false;
          case 'setCapturePhotos':
          case 'deleteAllPhotos':
            return true;
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('parses the storage stats the native side reports', () async {
      final stats = await NotificationRepository().getPhotoStorageStats();
      expect(stats.count, 3);
      expect(stats.formattedSize, '2.0 MB');
    });

    test('passes the switch value through to the native listener', () async {
      final ok = await NotificationRepository().setCapturePhotos(false);
      expect(ok, true);
      expect(calls.single.method, 'setCapturePhotos');
      expect(calls.single.arguments, {'enabled': false});
    });

    test('reads the switch back from the native side', () async {
      expect(await NotificationRepository().getCapturePhotos(), false);
    });

    test('deleteAllPhotos reports success', () async {
      expect(await NotificationRepository().deleteAllPhotos(), true);
    });

    test('falls back to safe defaults when the platform call fails', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'boom');
      });
      final repo = NotificationRepository();
      expect((await repo.getPhotoStorageStats()).count, 0);
      // Capture defaults to on: a failed read must not silently turn it off.
      expect(await repo.getCapturePhotos(), true);
      expect(await repo.deleteAllPhotos(), false);
    });
  });
}
