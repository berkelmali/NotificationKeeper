import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import '../repositories/notification_repository.dart';

/// New feature: real round-trip backup/restore, with optional passphrase-based
/// encryption. Backups are plain JSON (optionally AES-256-CBC encrypted) so
/// they're portable and future-proof, rather than raw DB files.
///
/// File format: a short plaintext header, then either the raw JSON or an
/// encrypted payload:
///   "NKPLAIN1:" + <json>
///   "NKENC1:"   + base64(iv) + ":" + base64(ciphertext)
///
/// The passphrase is hashed with SHA-256 to derive an AES-256 key. This is
/// simpler than a proper PBKDF2/Argon2 KDF and gives up some brute-force
/// resistance for a much smaller, easier-to-verify implementation - it's a
/// reasonable step up from an unencrypted file, but a determined attacker
/// with the file and lots of compute is a threat model this doesn't fully
/// address. Flagged here and in the changelog rather than glossed over.
class BackupService {
  final NotificationRepository repository;

  BackupService(this.repository);

  static const String _plainHeader = 'NKPLAIN1:';
  static const String _encHeader = 'NKENC1:';
  static const int _backupFormatVersion = 1;

  enc.Key _deriveKey(String passphrase) {
    final hash = sha256.convert(utf8.encode(passphrase));
    return enc.Key(Uint8List.fromList(hash.bytes));
  }

  /// Gathers notifications + settings and writes a backup file to a
  /// temporary directory, returning its path (ready to be shared via
  /// share_plus or moved elsewhere by the caller). [passphrase] is optional;
  /// leave null/empty for an unencrypted backup. [directoryOverride] is
  /// mainly for tests (avoids needing the path_provider platform channel);
  /// production callers can omit it.
  Future<String> createBackup({
    String? passphrase,
    Directory? directoryOverride,
  }) async {
    final notifications = await repository.getAllNotifications();
    final apps = await repository.getMonitoredApps();
    final keywords = await repository.getKeywords();
    final retentionDays = await repository.getRetentionDays();

    final backupData = {
      'formatVersion': _backupFormatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'app': 'Notification Keeper',
      'notifications': notifications
          .map((n) => {
                'packageName': n.packageName,
                'title': n.title,
                'content': n.content,
                'subText': n.subText,
                'timestamp': n.timestamp,
                'category': n.category,
                'groupKey': n.groupKey,
                'isGroupSummary': n.isGroupSummary,
                'messagingUser': n.messagingUser,
                'isRead': n.isRead,
                'isStarred': n.isStarred,
                'tags': n.tags,
                'isOtp': n.isOtp,
                'extractedCode': n.extractedCode,
                'isPriorityFlagged': n.isPriorityFlagged,
                // imagePath intentionally omitted - the underlying image files
                // aren't bundled into the backup to keep it a portable single file.
              })
          .toList(),
      'monitoredPackageNames':
          apps.where((a) => a.isMonitored).map((a) => a.packageName).toList(),
      'priorityKeywords': keywords,
      'retentionDays': retentionDays,
    };

    final jsonString = jsonEncode(backupData);

    String fileContent;
    if (passphrase != null && passphrase.isNotEmpty) {
      final key = _deriveKey(passphrase);
      final iv = enc.IV.fromLength(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(jsonString, iv: iv);
      fileContent = '$_encHeader${iv.base64}:${encrypted.base64}';
    } else {
      fileContent = '$_plainHeader$jsonString';
    }

    final dir = directoryOverride ?? await getTemporaryDirectory();
    final fileName =
        'notification_keeper_backup_${DateTime.now().millisecondsSinceEpoch}.nkbackup';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(fileContent);
    return file.path;
  }

  /// Reads a backup file and restores its notifications + settings into the
  /// app. Returns a [BackupRestoreResult] describing what happened - never
  /// throws for "expected" failure cases (wrong passphrase, corrupt/foreign
  /// file), only for genuinely unexpected I/O errors.
  Future<BackupRestoreResult> restoreBackup({
    required String filePath,
    String? passphrase,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return BackupRestoreResult.failure('File not found.');
    }

    final rawContent = await file.readAsString();
    String jsonString;

    if (rawContent.startsWith(_encHeader)) {
      if (passphrase == null || passphrase.isEmpty) {
        return BackupRestoreResult.failure(
            'This backup is encrypted. Enter the passphrase to restore it.');
      }
      try {
        final payload = rawContent.substring(_encHeader.length);
        final parts = payload.split(':');
        if (parts.length != 2) {
          return BackupRestoreResult.failure('Backup file looks corrupted.');
        }
        final iv = enc.IV.fromBase64(parts[0]);
        final key = _deriveKey(passphrase);
        final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
        jsonString = encrypter.decrypt64(parts[1], iv: iv);
      } catch (e) {
        return BackupRestoreResult.failure(
            'Could not decrypt this backup. Wrong passphrase, or the file is corrupted.');
      }
    } else if (rawContent.startsWith(_plainHeader)) {
      jsonString = rawContent.substring(_plainHeader.length);
    } else {
      return BackupRestoreResult.failure(
          'This doesn\'t look like a Notification Keeper backup file.');
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return BackupRestoreResult.failure('Backup file contents are invalid.');
    }

    try {
      final notifList = (data['notifications'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      final restoredCount = await repository.restoreNotifications(notifList);

      // Restore settings (best-effort - a failure here doesn't roll back
      // notifications that already restored successfully)
      final monitoredPackages =
          (data['monitoredPackageNames'] as List<dynamic>? ?? []).cast<String>();
      for (final pkg in monitoredPackages) {
        await repository.toggleAppMonitoring(pkg, true);
      }

      final keywords =
          (data['priorityKeywords'] as List<dynamic>? ?? []).cast<String>();
      if (keywords.isNotEmpty) {
        await repository.updateKeywords(keywords);
      }

      final retentionDays = data['retentionDays'] as int?;
      if (retentionDays != null) {
        await repository.setRetentionDays(retentionDays);
      }

      return BackupRestoreResult.success(restoredCount);
    } catch (e) {
      return BackupRestoreResult.failure('Restore failed: $e');
    }
  }
}

class BackupRestoreResult {
  final bool isSuccess;
  final int restoredCount;
  final String? errorMessage;

  BackupRestoreResult._(this.isSuccess, this.restoredCount, this.errorMessage);

  factory BackupRestoreResult.success(int count) =>
      BackupRestoreResult._(true, count, null);

  factory BackupRestoreResult.failure(String message) =>
      BackupRestoreResult._(false, 0, message);
}
