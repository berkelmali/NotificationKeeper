import 'package:flutter_test/flutter_test.dart';
import 'package:app/domain/apps/known_apps.dart';

void main() {
  group('KnownApps.prettify - the fallback when Android cannot name an app', () {
    // The old guesser took the last package segment: these all came out wrong.
    test('Telegram is Telegram, not "Messenger"', () {
      expect(KnownApps.prettify('org.telegram.messenger'), 'Telegram');
    });

    test('Instagram is Instagram, not "Android"', () {
      expect(KnownApps.prettify('com.instagram.android'), 'Instagram');
    });

    test('skips generic segments such as mobile and app', () {
      expect(KnownApps.prettify('com.mybank.mobile'), 'Mybank');
      expect(KnownApps.prettify('com.acme.app'), 'Acme');
    });

    test('turns underscores and camelCase into words', () {
      expect(KnownApps.prettify('com.foo.my_bank'), 'My Bank');
      expect(KnownApps.prettify('com.foo.pocketWallet'), 'Pocket Wallet');
    });

    test('keeps working for odd package names', () {
      expect(KnownApps.prettify('standalonepkg'), 'Standalonepkg');
      expect(KnownApps.prettify('com.android'), 'Android');
      expect(KnownApps.prettify(''), '');
    });
  });

  group('KnownApps.labelFor', () {
    test('uses the verified table where a guess would be wrong', () {
      expect(KnownApps.labelFor('com.google.android.gm'), 'Gmail'); // guess: "Gm"
      expect(KnownApps.labelFor('com.facebook.orca'), 'Messenger'); // guess: "Orca"
      expect(KnownApps.labelFor('trendyol.com'), 'Trendyol'); // guess: "Trendyol" anyway, but verified
    });

    test('falls back to prettify for anything not in the table', () {
      expect(KnownApps.labelFor('com.example.nksim'), 'Nksim');
    });
  });

  group('KnownApps.table', () {
    test('every entry has a non-empty name', () {
      for (final entry in KnownApps.table.entries) {
        expect(entry.value.name.trim(), isNotEmpty, reason: entry.key);
      }
    });

    test('ids that failed Google Play verification stay out', () {
      // Checked against Google Play on 2026-10-04: wrong ids, a discontinued app,
      // and one that could not be verified from Turkey.
      for (final rejected in const [
        'com.trendyol.android',
        'finansbank.enpara',
        'com.skype.raider',
        'com.discord',
      ]) {
        expect(KnownApps.table.containsKey(rejected), isFalse, reason: rejected);
      }
    });

    test('messaging apps are flagged, so setup can suggest them', () {
      expect(KnownApps.isMessaging('com.whatsapp'), isTrue);
      expect(KnownApps.isMessaging('org.telegram.messenger'), isTrue);
      expect(KnownApps.isMessaging('com.turkcell.bip'), isTrue);
      expect(KnownApps.isMessaging('com.google.android.youtube'), isFalse);
      expect(KnownApps.isMessaging('com.unknown.thing'), isFalse);
    });
  });
}
