import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/domain/models/app_info_model.dart';
import 'package:app/l10n/generated/app_localizations.dart';
import 'package:app/presentation/providers/app_list_provider.dart';
import 'package:app/presentation/providers/settings_provider.dart';
import 'package:app/presentation/screens/app_picker_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.example.notification_keeper/notifications');
  const smsApp = 'com.samsung.android.messaging';

  late List<Map<String, Object?>> installed;
  late Map<String, bool> toggled;

  Map<String, Object?> app(String packageName, String name, {bool monitored = false}) => {
        'packageName': packageName,
        'appName': name,
        'isMonitored': monitored,
        'notificationCount': 0,
        'isSystem': false,
        'isLaunchable': true,
      };

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    installed = [
      app('com.google.android.youtube', 'YouTube'),
      app('com.whatsapp', 'WhatsApp'),
      app('com.mybank.mobile', 'My Bank'),
      app(smsApp, 'Messages'),
    ];
    toggled = {};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'getMonitoredApps':
          return installed;
        case 'getDefaultSmsPackage':
          return smsApp;
        case 'toggleAppMonitoring':
          final args = call.arguments as Map;
          toggled[args['packageName'] as String] = args['isMonitored'] as bool;
          return true;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  Future<SettingsProvider> pumpPicker(WidgetTester tester, {bool settle = true}) async {
    // A phone-shaped surface tall enough for every row to be built.
    tester.view.physicalSize = const Size(1080, 3600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);
    final settings = SettingsProvider();
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppListProvider()),
        ChangeNotifierProvider.value(value: settings),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AppPickerScreen(),
      ),
    ));
    if (settle) await tester.pumpAndSettle();
    return settings;
  }

  group('AppPickerScreen.suggested', () {
    List<AppInfoModel> models(List<String> packages) =>
        [for (final p in packages) AppInfoModel(packageName: p, appName: p, isMonitored: false)];

    test('ticks chat apps from the verified table', () {
      expect(
        AppPickerScreen.suggested(models(['com.whatsapp', 'org.telegram.messenger', 'com.google.android.youtube']), null),
        {'com.whatsapp', 'org.telegram.messenger'},
      );
    });

    test('ticks the phone\'s SMS app whatever its brand, for verification codes', () {
      expect(AppPickerScreen.suggested(models([smsApp, 'com.mybank.mobile']), smsApp), {smsApp});
    });

    test('ignores an SMS app that is not in the list', () {
      expect(AppPickerScreen.suggested(models(['com.mybank.mobile']), smsApp), isEmpty);
    });
  });

  testWidgets('keeps the suggested apps: chats and the SMS app', (tester) async {
    final settings = await pumpPicker(tester);

    expect(find.text('Pick the apps to keep'), findsOneWidget);
    expect(find.text('Your SMS app - verification codes arrive here'), findsOneWidget);
    await tester.tap(find.text('Keep 2 apps'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(toggled, {'com.whatsapp': true, smsApp: true});
    expect(settings.appPickerDone, isTrue);
  });

  testWidgets('ticking another app adds it', (tester) async {
    await pumpPicker(tester);

    await tester.tap(find.text('My Bank'));
    await tester.pump();
    await tester.tap(find.text('Keep 3 apps'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(toggled.keys, unorderedEquals(['com.whatsapp', smsApp, 'com.mybank.mobile']));
  });

  testWidgets('with nothing ticked the button asks for an app and does nothing', (tester) async {
    final settings = await pumpPicker(tester);

    await tester.tap(find.text('WhatsApp'));
    await tester.tap(find.text('Messages'));
    await tester.pump();
    expect(find.text('Tick at least one app'), findsOneWidget);

    await tester.tap(find.text('Tick at least one app'));
    await tester.pumpAndSettle();
    expect(toggled, isEmpty);
    expect(settings.appPickerDone, isFalse);
  });

  testWidgets('search narrows the list', (tester) async {
    await pumpPicker(tester);

    await tester.enterText(find.byType(TextField), 'tube');
    await tester.pump();
    expect(find.text('YouTube'), findsOneWidget);
    expect(find.text('WhatsApp'), findsNothing);
    expect(find.text('Keep 2 apps'), findsOneWidget, reason: 'hidden apps stay ticked');
  });

  testWidgets('skipping moves on without switching anything on', (tester) async {
    final settings = await pumpPicker(tester);

    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();
    expect(settings.appPickerDone, isTrue);
    expect(toggled, isEmpty);
  });

  testWidgets('someone already keeping an app is never asked', (tester) async {
    installed[1] = app('com.whatsapp', 'WhatsApp', monitored: true);
    final settings = await pumpPicker(tester, settle: false);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(settings.appPickerDone, isTrue);
    expect(find.text('Pick the apps to keep'), findsNothing);
    expect(toggled, isEmpty);
  });
}
