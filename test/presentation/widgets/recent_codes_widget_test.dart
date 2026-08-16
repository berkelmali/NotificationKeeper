import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/domain/models/notification_model.dart';
import 'package:app/presentation/widgets/recent_codes_widget.dart';
import 'package:app/l10n/generated/app_localizations.dart';

/// Wraps [child] with the same localization setup main.dart uses in
/// production, since RecentCodesWidget reads AppLocalizations.of(context).
Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

NotificationModel _notif({
  required int id,
  bool isOtp = false,
  String? extractedCode,
}) {
  return NotificationModel(
    id: id,
    packageName: 'com.whatsapp',
    timestamp: 1700000000000,
    isGroupSummary: false,
    isOtp: isOtp,
    extractedCode: extractedCode,
  );
}

void main() {
  group('RecentCodesWidget visibility', () {
    testWidgets('renders nothing when there are no notifications at all',
        (tester) async {
      await tester.pumpWidget(_wrap(const RecentCodesWidget(notifications: [])));
      expect(find.byType(RecentCodesWidget), findsOneWidget);
      expect(find.text('RECENT CODES'), findsNothing);
    });

    testWidgets('renders nothing when no notification is OTP-flagged',
        (tester) async {
      final notifications = [
        _notif(id: 1, isOtp: false),
        _notif(id: 2, isOtp: false),
      ];
      await tester.pumpWidget(_wrap(RecentCodesWidget(notifications: notifications)));
      expect(find.text('RECENT CODES'), findsNothing);
    });

    testWidgets(
        'renders nothing for a notification flagged isOtp=true but with a '
        'null/empty extractedCode (defensive: flag and code should travel together, '
        'but the UI must not crash or show a blank chip if they do not)',
        (tester) async {
      final notifications = [_notif(id: 1, isOtp: true, extractedCode: null)];
      await tester.pumpWidget(_wrap(RecentCodesWidget(notifications: notifications)));
      expect(find.text('RECENT CODES'), findsNothing);
    });

    testWidgets('shows the header and the code when an OTP notification is present',
        (tester) async {
      final notifications = [_notif(id: 1, isOtp: true, extractedCode: '482913')];
      await tester.pumpWidget(_wrap(RecentCodesWidget(notifications: notifications)));

      expect(find.text('RECENT CODES'), findsOneWidget);
      expect(find.text('482913'), findsOneWidget);
    });

    testWidgets('filters out non-OTP notifications while keeping OTP ones',
        (tester) async {
      final notifications = [
        _notif(id: 1, isOtp: false),
        _notif(id: 2, isOtp: true, extractedCode: '111111'),
        _notif(id: 3, isOtp: false),
      ];
      await tester.pumpWidget(_wrap(RecentCodesWidget(notifications: notifications)));

      expect(find.text('111111'), findsOneWidget);
    });
  });

  group('RecentCodesWidget tap-to-copy / auto-mask', () {
    testWidgets('tapping a code chip copies it to the clipboard', (tester) async {
      final copied = <ClipboardData>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add(ClipboardData(text: call.arguments['text'] as String));
        }
        return null;
      });
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      final notifications = [_notif(id: 1, isOtp: true, extractedCode: '999000')];
      await tester.pumpWidget(_wrap(RecentCodesWidget(notifications: notifications)));

      await tester.tap(find.text('999000'));
      await tester.pump();

      expect(copied.map((c) => c.text), contains('999000'));

      // The tap also starts a 3-second auto-mask timer inside the widget;
      // let it run to completion before the test tears the tree down, or
      // flutter_test reports "A Timer is still pending" for this test.
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('the code auto-masks a few seconds after being copied',
        (tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async => null);
      addTearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null);
      });

      final notifications = [_notif(id: 1, isOtp: true, extractedCode: '555555')];
      await tester.pumpWidget(_wrap(RecentCodesWidget(notifications: notifications)));

      expect(find.text('555555'), findsOneWidget);

      await tester.tap(find.text('555555'));
      await tester.pump(); // process the tap + kick off the snackbar/mask timer

      // Not masked yet - the code masks itself a few seconds after copying,
      // not instantly.
      expect(find.text('555555'), findsOneWidget);

      await tester.pump(const Duration(seconds: 4));

      // Masked now: the digits are replaced with bullet characters, same length.
      expect(find.text('555555'), findsNothing);
      expect(find.text('•' * 6), findsOneWidget);
    });
  });
}
