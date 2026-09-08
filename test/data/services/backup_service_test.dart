import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
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

    test('writes an encrypted file (NKENC2: header) when a passphrase is given, '
        'and the plaintext content is not visible anywhere in the file', () async {
      final service = BackupService(NotificationRepository());
      final path = await service.createBackup(
        passphrase: 'correct horse battery staple',
        directoryOverride: tempDir,
      );

      final content = await File(path).readAsString();
      expect(content.startsWith('NKENC2:'), true);
      // The whole point of encryption: sensitive captured content (like an
      // OTP code) must not appear in cleartext in the encrypted file.
      expect(content, isNot(contains('123456')));
      expect(content, isNot(contains('com.whatsapp')));
    });

    test('encrypting the same archive twice produces different ciphertext '
        '(regression: the IV used to be a fixed block of zero bytes, which made '
        'AES-CBC deterministic and leaked how much two backups had in common)',
        () async {
      final service = BackupService(NotificationRepository());

      final first = await File(await service.createBackup(
        passphrase: 'same-passphrase-both-times',
        directoryOverride: tempDir,
      )).readAsString();
      final second = await File(await service.createBackup(
        passphrase: 'same-passphrase-both-times',
        directoryOverride: tempDir,
      )).readAsString();

      // Both are encrypted...
      expect(first.startsWith('NKENC2:'), true);
      expect(second.startsWith('NKENC2:'), true);
      // ...with different IVs, so the payloads cannot match.
      // NKENC2:<iterations>:<salt>:<iv>:<ciphertext> - the IV is field 2.
      final firstIv = first.substring('NKENC2:'.length).split(':')[2];
      final secondIv = second.substring('NKENC2:'.length).split(':')[2];
      expect(firstIv, isNot(equals(secondIv)));
      expect(first, isNot(equals(second)));
    });

    test('writes the current NKENC2 header with a per-file salt and iteration '
        'count, so the KDF cost can be raised later without stranding old files',
        () async {
      final service = BackupService(NotificationRepository());

      final first = await File(await service.createBackup(
        passphrase: 'salted',
        directoryOverride: tempDir,
      )).readAsString();
      final second = await File(await service.createBackup(
        passphrase: 'salted',
        directoryOverride: tempDir,
      )).readAsString();

      // NKENC2:<iterations>:<salt>:<iv>:<ciphertext>
      final parts = first.substring('NKENC2:'.length).split(':');
      expect(parts.length, 4);
      expect(int.parse(parts[0]), greaterThanOrEqualTo(100000));
      expect(base64Decode(parts[1]).length, 16);

      // Salt must differ per file, or it is not doing its job.
      final secondSalt = second.substring('NKENC2:'.length).split(':')[1];
      expect(parts[1], isNot(equals(secondSalt)));
    });

    test('a randomly-IV\'d backup still round-trips with its passphrase', () async {
      final service = BackupService(NotificationRepository());
      final path = await service.createBackup(
        passphrase: 'random-iv-round-trip',
        directoryOverride: tempDir,
      );

      final result = await service.restoreBackup(
        filePath: path,
        passphrase: 'random-iv-round-trip',
      );

      expect(result.isSuccess, true);
      expect(result.restoredCount, 1);
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

    test('a legacy NKENC1 backup (unsalted SHA-256 key, written before the '
        'PBKDF2 change) still restores - upgrading must not orphan the files '
        'users already have', () async {
      // Build a file exactly the way the old implementation did.
      const passphrase = 'an-old-backup';
      final payload = jsonEncode({
        'formatVersion': 1,
        'exportedAt': '2025-01-01T00:00:00.000',
        'app': 'Notification Keeper',
        'notifications': [
          {
            'packageName': 'com.whatsapp',
            'title': 'Alice',
            'content': 'Hello from the past',
            'timestamp': 1700000000000,
            'isGroupSummary': false,
            'isRead': false,
            'isStarred': false,
            'isOtp': false,
            'isPriorityFlagged': false,
          }
        ],
        'monitoredPackageNames': <String>[],
        'priorityKeywords': <String>[],
        'retentionDays': 7,
      });

      final legacyKey =
          enc.Key(Uint8List.fromList(sha256.convert(utf8.encode(passphrase)).bytes));
      final legacyIv = enc.IV.fromLength(16); // the old all-zero IV
      final legacyCipher = enc
          .Encrypter(enc.AES(legacyKey, mode: enc.AESMode.cbc))
          .encrypt(payload, iv: legacyIv);

      final legacyFile = File('${tempDir.path}/legacy.nkbackup');
      await legacyFile
          .writeAsString('NKENC1:${legacyIv.base64}:${legacyCipher.base64}');

      final service = BackupService(NotificationRepository());
      final result = await service.restoreBackup(
        filePath: legacyFile.path,
        passphrase: passphrase,
      );

      expect(result.isSuccess, true);
      expect(result.restoredCount, 1);
    });

    test('a legacy NKENC1 backup with the wrong passphrase still fails cleanly',
        () async {
      final key =
          enc.Key(Uint8List.fromList(sha256.convert(utf8.encode('right')).bytes));
      final iv = enc.IV.fromLength(16);
      final cipher = enc
          .Encrypter(enc.AES(key, mode: enc.AESMode.cbc))
          .encrypt('{"notifications":[]}', iv: iv);

      final legacyFile = File('${tempDir.path}/legacy_wrong.nkbackup');
      await legacyFile.writeAsString('NKENC1:${iv.base64}:${cipher.base64}');

      final service = BackupService(NotificationRepository());
      final result = await service.restoreBackup(
        filePath: legacyFile.path,
        passphrase: 'wrong',
      );

      expect(result.isSuccess, false);
      expect(result.errorMessage, isNotNull);
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
