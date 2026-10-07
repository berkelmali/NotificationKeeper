import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/presentation/widgets/pin_pad.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: SingleChildScrollView(child: child))));

Future<void> _type(WidgetTester tester, String digits) async {
  for (final d in digits.split('')) {
    await tester.tap(find.text(d));
    await tester.pump();
  }
}

void main() {
  group('formatLockoutTime', () {
    test('counts down as m:ss, the same in every language', () {
      expect(formatLockoutTime(const Duration(seconds: 30)), '0:30');
      expect(formatLockoutTime(const Duration(minutes: 1, seconds: 1)), '1:01');
      expect(formatLockoutTime(const Duration(minutes: 59, seconds: 59)), '59:59');
    });

    test('rounds up, so a fresh lockout does not start a second short', () {
      expect(formatLockoutTime(const Duration(seconds: 29, milliseconds: 200)), '0:30');
      expect(formatLockoutTime(const Duration(milliseconds: 1)), '0:01');
    });

    test('shows hours past the hour', () {
      expect(formatLockoutTime(const Duration(hours: 1)), '1:00:00');
      expect(formatLockoutTime(const Duration(hours: 1, minutes: 5, seconds: 9)), '1:05:09');
    });
  });

  testWidgets('submits the digits typed once the minimum length is reached', (tester) async {
    String? submitted;
    await tester.pumpWidget(_host(PinPad(
      title: 'Enter PIN',
      submitLabel: 'Unlock',
      deleteLabel: 'Delete',
      onSubmit: (pin) => submitted = pin,
    )));

    await _type(tester, '123');
    await tester.tap(find.text('Unlock'));
    expect(submitted, isNull, reason: 'three digits is below the minimum');

    await _type(tester, '4');
    await tester.tap(find.text('Unlock'));
    expect(submitted, '1234');
  });

  testWidgets('delete removes the last digit', (tester) async {
    String? submitted;
    await tester.pumpWidget(_host(PinPad(
      title: 'Enter PIN',
      submitLabel: 'Unlock',
      deleteLabel: 'Delete',
      onSubmit: (pin) => submitted = pin,
    )));

    await _type(tester, '12345');
    await tester.tap(find.bySemanticsLabel('Delete'));
    await tester.pump();
    await tester.tap(find.text('Unlock'));
    expect(submitted, '1234');
  });

  testWidgets('stops accepting digits at the maximum length', (tester) async {
    String? submitted;
    await tester.pumpWidget(_host(PinPad(
      title: 'Enter PIN',
      submitLabel: 'Unlock',
      deleteLabel: 'Delete',
      maxLength: 6,
      onSubmit: (pin) => submitted = pin,
    )));

    await _type(tester, '12345678');
    await tester.tap(find.text('Unlock'));
    expect(submitted, '123456');
  });

  testWidgets('a wrong-PIN signal clears the pad and shows the error', (tester) async {
    String? submitted;
    var signal = 0;
    late StateSetter rebuild;
    await tester.pumpWidget(_host(StatefulBuilder(builder: (context, setState) {
      rebuild = setState;
      return PinPad(
        title: 'Enter PIN',
        submitLabel: 'Unlock',
        deleteLabel: 'Delete',
        errorText: signal > 0 ? 'Wrong PIN' : null,
        errorSignal: signal,
        onSubmit: (pin) => submitted = pin,
      );
    })));

    await _type(tester, '9999');
    rebuild(() => signal++);
    await tester.pumpAndSettle();

    expect(find.text('Wrong PIN'), findsOneWidget);
    await tester.tap(find.text('Unlock'));
    expect(submitted, isNull, reason: 'the wrong PIN was cleared');
  });

  testWidgets('the fingerprint key appears only when biometric unlock is offered', (tester) async {
    await tester.pumpWidget(_host(PinPad(
      title: 'Enter PIN',
      submitLabel: 'Unlock',
      deleteLabel: 'Delete',
      onSubmit: (_) {},
    )));
    expect(find.byIcon(Icons.fingerprint_rounded), findsNothing);

    var asked = false;
    await tester.pumpWidget(_host(PinPad(
      title: 'Enter PIN',
      submitLabel: 'Unlock',
      deleteLabel: 'Delete',
      biometricLabel: 'Use fingerprint',
      onBiometric: () => asked = true,
      onSubmit: (_) {},
    )));
    await tester.tap(find.byIcon(Icons.fingerprint_rounded));
    expect(asked, isTrue);
  });
}
