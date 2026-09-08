import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart' as pc;
import '../repositories/notification_repository.dart';

/// New feature: real round-trip backup/restore, with optional passphrase-based
/// encryption. Backups are plain JSON (optionally AES-256-CBC encrypted) so
/// they're portable and future-proof, rather than raw DB files.
///
/// File format: a short plaintext header, then either the raw JSON or an
/// encrypted payload.
///
/// ```text
/// NKPLAIN1:<json>
/// NKENC2:<iterations>:<b64 salt>:<b64 iv>:<b64 ciphertext>   (current)
/// NKENC1:<b64 iv>:<b64 ciphertext>                           (legacy, read-only)
/// ```
///
/// ## Key derivation
///
/// `NKENC2` derives the AES-256 key with PBKDF2-HMAC-SHA256 over a random
/// 16-byte salt. The old `NKENC1` format used a bare SHA-256 of the passphrase:
/// one hash invocation, no salt, so an attacker holding a backup file could try
/// candidate passphrases at the speed of raw hashing, and a precomputed table
/// worked against every user at once. PBKDF2 makes each guess cost
/// [_pbkdf2Iterations] hash rounds and the salt makes the work per-file.
///
/// The iteration count and salt are stored in the file rather than hardcoded in
/// the reader, so the count can be raised later without stranding backups that
/// were written under the old one. `NKENC1` files still restore - they carry
/// their own parameters too, just weaker ones.
class BackupService {
  final NotificationRepository repository;

  BackupService(this.repository);

  static const String _plainHeader = 'NKPLAIN1:';

  /// Legacy header: unsalted SHA-256 key derivation. Read, never written.
  static const String _legacyEncHeader = 'NKENC1:';

  /// Current header: salted PBKDF2 key derivation.
  static const String _encHeader = 'NKENC2:';

  static const int _backupFormatVersion = 1;

  /// Chosen so a wrong-guess attempt costs real work while a legitimate
  /// restore on a mid-range phone still finishes in well under a second -
  /// PBKDF2 here is pure Dart, not a native implementation.
  static const int _pbkdf2Iterations = 120000;
  static const int _saltLength = 16;

  /// Legacy `NKENC1` derivation. Kept only so older backups keep restoring.
  enc.Key _deriveLegacyKey(String passphrase) {
    final hash = sha256.convert(utf8.encode(passphrase));
    return enc.Key(Uint8List.fromList(hash.bytes));
  }

  enc.Key _deriveKey(String passphrase, Uint8List salt, int iterations) {
    final derivator = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64))
      ..init(pc.Pbkdf2Parameters(salt, iterations, 32));
    return enc.Key(derivator.process(Uint8List.fromList(utf8.encode(passphrase))));
  }

  Uint8List _randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => random.nextInt(256)));
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
                // New features A & B: keep the "withdrawn by sender" marker and
                // the "code already shredded" flag across a restore.
                'recalledAt': n.recalledAt,
                'codeShredded': n.codeShredded,
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
      final salt = _randomBytes(_saltLength);
      final key = _deriveKey(passphrase, salt, _pbkdf2Iterations);
      // The IV used to be IV.fromLength(16) - a block of zero bytes, not a
      // random IV. With a deterministic key that made AES-CBC deterministic:
      // the same archive encrypted twice produced byte-identical files, and two
      // backups sharing a passphrase leaked how much of their content matched
      // from the front. Both the IV and the salt are public by design and ride
      // along in the file, so generating them fresh costs nothing.
      final iv = enc.IV.fromSecureRandom(16);
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      final encrypted = encrypter.encrypt(jsonString, iv: iv);
      fileContent = '$_encHeader$_pbkdf2Iterations:'
          '${base64Encode(salt)}:${iv.base64}:${encrypted.base64}';
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

    final isCurrentFormat = rawContent.startsWith(_encHeader);
    final isLegacyFormat = rawContent.startsWith(_legacyEncHeader);

    if (isCurrentFormat || isLegacyFormat) {
      if (passphrase == null || passphrase.isEmpty) {
        return BackupRestoreResult.failure(
            'This backup is encrypted. Enter the passphrase to restore it.');
      }
      try {
        final enc.Key key;
        final enc.IV iv;
        final String ciphertext;

        if (isCurrentFormat) {
          // NKENC2:<iterations>:<salt>:<iv>:<ciphertext>
          final parts = rawContent.substring(_encHeader.length).split(':');
          if (parts.length != 4) {
            return BackupRestoreResult.failure('Backup file looks corrupted.');
          }
          final iterations = int.tryParse(parts[0]);
          if (iterations == null || iterations <= 0) {
            return BackupRestoreResult.failure('Backup file looks corrupted.');
          }
          key = _deriveKey(passphrase, base64Decode(parts[1]), iterations);
          iv = enc.IV.fromBase64(parts[2]);
          ciphertext = parts[3];
        } else {
          // NKENC1:<iv>:<ciphertext> - written by versions before the KDF
          // change. Still restorable; only new backups get the stronger one.
          final parts = rawContent.substring(_legacyEncHeader.length).split(':');
          if (parts.length != 2) {
            return BackupRestoreResult.failure('Backup file looks corrupted.');
          }
          key = _deriveLegacyKey(passphrase);
          iv = enc.IV.fromBase64(parts[0]);
          ciphertext = parts[1];
        }

        final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
        jsonString = encrypter.decrypt64(ciphertext, iv: iv);
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
