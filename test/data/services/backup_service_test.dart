import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/data/repositories/notification_repository.dart';
import 'package:app/data/services/backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.example.notification_keeper/notifications');
  late Directory tempDir;
  late List<MethodCall> nativeCalls;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('backup_service_test_');
    nativeCalls = [];

    // Fakes the native side so these tests run on plain `flutter test`
    // without a device/emulator. Mirrors the shape of what MainActivity.kt
    // actually returns for each method.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      nativeCalls.add(call);
      switch (call.method) {
        case 'getAllNotifications':
          return [
            {
              'id': 1,
              'packageName': 'com.whatsapp',
              'title': 'Alice',
              'content': 'Your code is 123456',
              'subText': null,
              'timestamp': 1700000000000,
              'category': null,
              'groupKey': null,
              'isGroupSummary': false,
              'messagingUser': 'Alice',
              'isRead': false,
              'isStarred': true,
              'tags': 'work',
              'isOtp': true,
              'extractedCode': '123456',
              'isPriorityFlagged': false,
              'imagePath': null,
            },
          ];
        case 'getMonitoredApps':
          return [
            {
              'packageName': 'com.whatsapp',
              'appName': 'WhatsApp',
              'isMonitored': true,
              'notificationCount': 1,
              'snoozedUntil': null,
            },
          ];
        case 'getKeywords':
          return ['urgent', 'invoice'];
        case 'getRetentionDays':
          return 30;
        case 'restoreNotifications':
          final items = call.arguments['notifications'] as List;
          return items.length;
        case 'toggleAppMonitoring':
          return true;
        case 'updateKeywords':
          return true;
        case 'setRetentionDays':
          return true;
        default:
          throw MissingPluginException('Unmocked method: ${call.method}');
      }
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('BackupService.createBackup', () {
    test('writes a plaintext file (NKPLAIN1: header) when no passphrase is given', () async {
      final service = BackupService(NotificationRepository());
      final path = await service.createBackup(directoryOverride: tempDir);

      final content = await File(path).readAsString();
      expect(content.startsWith('NKPLAIN1:'), true);
      expect(content, contains('com.whatsapp'));
      expect(content, contains('123456'));
    });

    test('writes an encrypted file (NKENC1: header) when a passphrase is given, '
        'and the plaintext content is not visible anywhere in the file', () async {
      final service = BackupService(NotificationRepository());
      final path = await service.createBackup(
        passphrase: 'correct horse battery staple',
        directoryOverride: tempDir,
      );

      final content = await File(path).readAsString();
      expect(content.startsWith('NKENC1:'), true);
      // The whole point of encryption: sensitive captured content (like an
      // OTP code) must not appear in cleartext in the encrypted file.
      expect(content, isNot(contains('123456')));
      expect(content, isNot(contains('com.whatsapp')));
    });

    test('gathers data from all four repository calls', () async {
      final service = BackupService(NotificationRepository());
      await service.createBackup(directoryOverride: tempDir);

      final calledMethods = nativeCalls.map((c) => c.method).toSet();
      expect(
        calledMethods,
        containsAll([
          'getAllNotifications',
          'getMonitoredApps',
          'getKeywords',
          'getRetentionDays',
        ]),
      );
    });
  });

  group('BackupService.restoreBackup round-trip', () {
    test('an unencrypted backup restores successfully', () async {
      final service = BackupService(NotificationRepository());
      final path = await service.createBackup(directoryOverride: tempDir);

      final result = await service.restoreBackup(filePath: path);

      expect(result.isSuccess, true);
      expect(result.restoredCount, 1);
    });

    test('an encrypted backup restores successfully with the correct passphrase', () async {
      final service = BackupService(NotificationRepository());
      final path = await service.createBackup(
        passphrase: 'hunter2-but-better',
        directoryOverride: tempDir,
      );

      final result = await service.restoreBackup(
        filePath: path,
        passphrase: 'hunter2-but-better',
      );

      expect(result.isSuccess, true);
      expect(result.restoredCount, 1);
    });

    test('an encrypted backup fails gracefully with the WRONG passphrase '
        '(must not throw, and must not silently "succeed" with garbage data)', () async {
      final service = BackupService(NotificationRepository());
      final path = await service.createBackup(
        passphrase: 'the-real-passphrase',
        directoryOverride: tempDir,
      );

      final result = await service.restoreBackup(
        filePath: path,
        passphrase: 'a-completely-wrong-guess',
      );

      expect(result.isSuccess, false);
      expect(result.errorMessage, isNotNull);
    });

    test('an encrypted backup fails gracefully when no passphrase is supplied at all', () async {
      final service = BackupService(NotificationRepository());
      final path = await service.createBackup(
        passphrase: 'set-on-creation',
        directoryOverride: tempDir,
      );

      final result = await service.restoreBackup(filePath: path);

      expect(result.isSuccess, false);
      expect(result.errorMessage, contains('passphrase'));
    });

    test('restoring a non-existent file fails gracefully instead of throwing', () async {
      final service = BackupService(NotificationRepository());
      final result = await service.restoreBackup(
        filePath: '${tempDir.path}/does_not_exist.nkbackup',
      );

      expect(result.isSuccess, false);
    });

    test('restoring a file that is not a Notification Keeper backup at all '
        'fails gracefully with a clear message', () async {
      final foreignFile = File('${tempDir.path}/random.txt');
      await foreignFile.writeAsString('just some unrelated text content');

      final service = BackupService(NotificationRepository());
      final result = await service.restoreBackup(filePath: foreignFile.path);

      expect(result.isSuccess, false);
      expect(result.errorMessage, isNotNull);
    });

    test('restoring pushes settings (keywords, retention) back through the repository', () async {
      final service = BackupService(NotificationRepository());
      final path = await service.createBackup(directoryOverride: tempDir);

      nativeCalls.clear();
      await service.restoreBackup(filePath: path);

      final calledMethods = nativeCalls.map((c) => c.method).toSet();
      expect(calledMethods, contains('restoreNotifications'));
      expect(calledMethods, contains('updateKeywords'));
      expect(calledMethods, contains('setRetentionDays'));
    });
  });
}
