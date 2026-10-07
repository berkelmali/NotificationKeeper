import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/presentation/providers/app_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.example.notification_keeper/notifications');
  late List<MethodCall> calls;
  final fakeIcon = Uint8List.fromList(const [137, 80, 78, 71]); // PNG magic

  setUp(() {
    calls = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (call.method != 'getAppIdentities') return null;
      final packages = (call.arguments['packages'] as List).cast<String>();
      return [
        for (final pkg in packages)
          if (pkg == 'org.telegram.messenger')
            {'packageName': pkg, 'label': 'Telegram', 'icon': fakeIcon, 'installed': true}
          else if (pkg == 'com.example.custom')
            {'packageName': pkg, 'label': 'My Custom App', 'icon': fakeIcon, 'installed': true}
          else
            {'packageName': pkg, 'label': null, 'icon': null, 'installed': false},
      ];
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('gives the right name before Android has even answered', () {
    final registry = AppRegistry();
    // Synchronous first paint: the verified table, not the old last-segment guess.
    expect(registry.labelFor('org.telegram.messenger'), 'Telegram');
    expect(registry.labelFor('com.google.android.gm'), 'Gmail');
    expect(registry.iconFor('org.telegram.messenger'), isNull);
  });

  test('batches every lookup requested in the same frame into one call', () async {
    final registry = AppRegistry();
    registry.ensure('org.telegram.messenger');
    registry.ensure('com.example.custom');
    registry.ensure('org.telegram.messenger'); // duplicate in the same frame
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(calls.where((c) => c.method == 'getAppIdentities').length, 1);
    expect(
      (calls.single.arguments['packages'] as List).toSet(),
      {'org.telegram.messenger', 'com.example.custom'},
    );
  });

  test('uses Android\'s label and icon once resolved, and notifies listeners', () async {
    final registry = AppRegistry();
    var notified = 0;
    registry.addListener(() => notified++);

    registry.ensure('com.example.custom');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(registry.labelFor('com.example.custom'), 'My Custom App');
    expect(registry.iconFor('com.example.custom'), fakeIcon);
    expect(registry.isResolved('com.example.custom'), isTrue);
    expect(notified, greaterThan(0));
  });

  test('does not ask again for a package it already resolved', () async {
    final registry = AppRegistry();
    registry.ensure('org.telegram.messenger');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    registry.ensure('org.telegram.messenger');
    await Future<void>.delayed(Duration.zero);

    expect(calls.where((c) => c.method == 'getAppIdentities').length, 1);
  });

  test('an uninstalled app falls back to the known-app table', () async {
    final registry = AppRegistry();
    registry.ensure('com.instagram.android');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final identity = registry.identityOf('com.instagram.android');
    expect(identity?.installed, isFalse);
    expect(registry.labelFor('com.instagram.android'), 'Instagram');
  });

  test('a failing platform call degrades to the best guess and stops retrying', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      throw PlatformException(code: 'PM_ERROR');
    });
    final registry = AppRegistry();
    registry.ensure('org.telegram.messenger');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    registry.ensure('org.telegram.messenger');
    await Future<void>.delayed(Duration.zero);

    expect(registry.labelFor('org.telegram.messenger'), 'Telegram');
    expect(calls.length, 1);
  });
}
