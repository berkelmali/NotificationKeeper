import 'package:flutter_test/flutter_test.dart';
import 'package:app/domain/models/notification_model.dart';

void main() {
  group('NotificationModel.fromMap', () {
    test('parses a fully-populated map, including merged fields', () {
      final map = <Object?, Object?>{
        'id': 42,
        'packageName': 'com.whatsapp',
        'title': 'Alice',
        'content': 'Your code is 123456',
        'subText': null,
        'timestamp': 1000000,
        'category': 'msg',
        'groupKey': 'g1',
        'isGroupSummary': false,
        'messagingUser': 'Alice',
        'isRead': true,
        'isStarred': false,
        'tags': 'work,urgent',
        'isOtp': true,
        'extractedCode': '123456',
        'isPriorityFlagged': true,
        'imagePath': '/data/user/0/.../img.jpg',
      };

      final model = NotificationModel.fromMap(map);

      expect(model.id, 42);
      expect(model.packageName, 'com.whatsapp');
      expect(model.isOtp, true);
      expect(model.extractedCode, '123456');
      expect(model.isPriorityFlagged, true);
      expect(model.imagePath, '/data/user/0/.../img.jpg');
    });

    test('accepts native boolean columns encoded as int 0/1 (SQLite/Room style)', () {
      final map = <Object?, Object?>{
        'id': 1,
        'packageName': 'com.example',
        'timestamp': 0,
        'isGroupSummary': 0,
        'isRead': 1,
        'isStarred': 0,
        'isOtp': 1,
        'isPriorityFlagged': 0,
      };

      final model = NotificationModel.fromMap(map);

      expect(model.isRead, true);
      expect(model.isStarred, false);
      expect(model.isOtp, true);
      expect(model.isPriorityFlagged, false);
    });

    test('defaults merged fields to false/null when the map omits them '
        '(guards against older cached data before the schema migration)', () {
      final map = <Object?, Object?>{
        'id': 1,
        'packageName': 'com.example',
        'timestamp': 0,
        'isGroupSummary': false,
      };

      final model = NotificationModel.fromMap(map);

      expect(model.isOtp, false);
      expect(model.extractedCode, isNull);
      expect(model.isPriorityFlagged, false);
      expect(model.imagePath, isNull);
    });
  });

  group('NotificationModel.tagList', () {
    test('splits comma-separated tags and trims whitespace', () {
      final model = _baseModel(tags: 'work, urgent ,billing');
      expect(model.tagList, ['work', 'urgent', 'billing']);
    });

    test('returns an empty list when tags is null', () {
      final model = _baseModel(tags: null);
      expect(model.tagList, isEmpty);
    });

    test('returns an empty list when tags is an empty string', () {
      final model = _baseModel(tags: '');
      expect(model.tagList, isEmpty);
    });

    test('drops empty segments from malformed input like "a,,b"', () {
      final model = _baseModel(tags: 'a,,b');
      expect(model.tagList, ['a', 'b']);
    });
  });

  group('NotificationModel.copyWith', () {
    test('overrides only the specified fields, keeping the rest', () {
      final original = _baseModel(isOtp: false, isPriorityFlagged: false);
      final updated = original.copyWith(isPriorityFlagged: true);

      expect(updated.isPriorityFlagged, true);
      // Untouched fields must survive the copy unchanged.
      expect(updated.isOtp, original.isOtp);
      expect(updated.id, original.id);
      expect(updated.packageName, original.packageName);
    });

    test('copyWith with no arguments returns an equivalent object', () {
      final original = _baseModel();
      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.imagePath, original.imagePath);
      expect(copy.extractedCode, original.extractedCode);
    });
  });
}

/// Small helper to build a valid model without repeating every required
/// field in each test case.
NotificationModel _baseModel({
  bool isOtp = false,
  bool isPriorityFlagged = false,
  String? tags,
}) {
  return NotificationModel(
    id: 1,
    packageName: 'com.example.app',
    timestamp: 1700000000000,
    isGroupSummary: false,
    tags: tags,
    isOtp: isOtp,
    isPriorityFlagged: isPriorityFlagged,
    imagePath: '/tmp/img.jpg',
    extractedCode: isOtp ? '000000' : null,
  );
}
