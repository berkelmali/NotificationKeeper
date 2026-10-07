/// Display names for apps when Android cannot tell us.
///
/// The authoritative name of an installed app comes from Android's
/// PackageManager (see AppRegistry). This table only matters when that is not
/// available - the app was uninstalled after its notifications were archived,
/// the archive was restored from a backup on another phone, or a lookup is
/// still in flight on first paint.
///
/// Every package id below was checked against Google Play
/// (`play.google.com/store/apps/details?id=…`) on 2026-10-04 and resolved to the
/// app named here. Four candidates were rejected by that check and are
/// deliberately absent: `com.trendyol.android` and `finansbank.enpara` (wrong
/// ids), `com.skype.raider` (Skype was shut down) and `com.discord` (Play does
/// not serve it in Turkey, where Discord is blocked, so it could not be
/// verified from here). Names are the short launcher-style brand name, not the
/// store listing title ("WhatsApp", not "WhatsApp Messenger").
library;

/// Rough grouping used to suggest which apps to protect during setup.
enum AppCategory { messaging, social, email, banking, shopping, government, media, other }

class KnownApp {
  final String name;
  final AppCategory category;

  const KnownApp(this.name, this.category);
}

class KnownApps {
  KnownApps._();

  static const Map<String, KnownApp> table = {
    // Messaging
    'com.whatsapp': KnownApp('WhatsApp', AppCategory.messaging),
    'com.whatsapp.w4b': KnownApp('WhatsApp Business', AppCategory.messaging),
    'org.telegram.messenger': KnownApp('Telegram', AppCategory.messaging),
    'org.thoughtcrime.securesms': KnownApp('Signal', AppCategory.messaging),
    'com.facebook.orca': KnownApp('Messenger', AppCategory.messaging),
    'com.viber.voip': KnownApp('Viber', AppCategory.messaging),
    'jp.naver.line.android': KnownApp('LINE', AppCategory.messaging),
    'com.google.android.apps.messaging': KnownApp('Messages', AppCategory.messaging),
    'com.google.android.apps.dynamite': KnownApp('Google Chat', AppCategory.messaging),
    'com.microsoft.teams': KnownApp('Teams', AppCategory.messaging),
    'com.Slack': KnownApp('Slack', AppCategory.messaging),
    'com.tencent.mm': KnownApp('WeChat', AppCategory.messaging),
    'com.kakao.talk': KnownApp('KakaoTalk', AppCategory.messaging),
    'com.turkcell.bip': KnownApp('BiP', AppCategory.messaging),

    // Social
    'com.instagram.android': KnownApp('Instagram', AppCategory.social),
    'com.snapchat.android': KnownApp('Snapchat', AppCategory.social),
    'com.zhiliaoapp.musically': KnownApp('TikTok', AppCategory.social),
    'com.twitter.android': KnownApp('X', AppCategory.social),
    'com.facebook.katana': KnownApp('Facebook', AppCategory.social),
    'com.linkedin.android': KnownApp('LinkedIn', AppCategory.social),
    'com.reddit.frontpage': KnownApp('Reddit', AppCategory.social),
    'com.pinterest': KnownApp('Pinterest', AppCategory.social),

    // Email
    'com.google.android.gm': KnownApp('Gmail', AppCategory.email),
    'com.microsoft.office.outlook': KnownApp('Outlook', AppCategory.email),

    // Banking & payments
    'com.garanti.cepsubesi': KnownApp('Garanti BBVA', AppCategory.banking),
    'com.ykb.android': KnownApp('Yapı Kredi', AppCategory.banking),
    'com.akbank.android.apps.akbank_direkt': KnownApp('Akbank', AppCategory.banking),
    'com.pozitron.iscep': KnownApp('İşCep', AppCategory.banking),
    'com.ziraat.ziraatmobil': KnownApp('Ziraat Mobil', AppCategory.banking),
    'com.vakifbank.mobile': KnownApp('VakıfBank', AppCategory.banking),
    'com.finansbank.mobile.cepsube': KnownApp('QNB Mobil', AppCategory.banking),
    'com.ingbanktr.ingmobil': KnownApp('ING Mobil', AppCategory.banking),
    'com.denizbank.mobildeniz': KnownApp('MobilDeniz', AppCategory.banking),
    'com.tmobtech.halkbank': KnownApp('Halkbank Mobil', AppCategory.banking),
    'com.teb': KnownApp('CEPTETEB', AppCategory.banking),
    'com.mobillium.papara': KnownApp('Papara', AppCategory.banking),

    // Shopping & delivery
    'trendyol.com': KnownApp('Trendyol', AppCategory.shopping),
    'com.pozitron.hepsiburada': KnownApp('Hepsiburada', AppCategory.shopping),
    'com.getir': KnownApp('Getir', AppCategory.shopping),
    'com.inovel.app.yemeksepeti': KnownApp('Yemeksepeti', AppCategory.shopping),
    'com.sahibinden': KnownApp('sahibinden', AppCategory.shopping),

    // Government
    'tr.gov.turkiye.edevlet.kapisi': KnownApp('e-Devlet', AppCategory.government),

    // Media & everyday Google
    'com.google.android.youtube': KnownApp('YouTube', AppCategory.media),
    'com.spotify.music': KnownApp('Spotify', AppCategory.media),
    'com.netflix.mediaclient': KnownApp('Netflix', AppCategory.media),
    'com.google.android.apps.photos': KnownApp('Google Photos', AppCategory.media),
    'com.google.android.calendar': KnownApp('Google Calendar', AppCategory.other),
    'com.google.android.apps.maps': KnownApp('Google Maps', AppCategory.other),
  };

  /// Package-name segments that say nothing about which app it is.
  static const Set<String> _genericSegments = {
    'com', 'org', 'net', 'io', 'co', 'tr', 'jp', 'de', 'uk', 'app', 'apps',
    'android', 'mobile', 'mobil', 'client', 'messenger', 'lite', 'free',
    'pro', 'prod', 'release', 'main', 'phone', 'launcher', 'ui', 'example',
  };

  /// Best name available without asking Android: the verified table first,
  /// then a readable guess built from the package name.
  static String labelFor(String packageName) =>
      table[packageName]?.name ?? prettify(packageName);

  static AppCategory categoryOf(String packageName) =>
      table[packageName]?.category ?? AppCategory.other;

  static bool isMessaging(String packageName) =>
      categoryOf(packageName) == AppCategory.messaging;

  /// Readable guess from a package name.
  ///
  /// The old guess took the last segment, which named Telegram "Messenger"
  /// (org.telegram.messenger) and Instagram "Android" (com.instagram.android).
  /// This takes the last segment that actually identifies something, and turns
  /// underscores and camelCase into words: `com.foo.my_bank` → "My Bank".
  static String prettify(String packageName) {
    final segments = packageName
        .split('.')
        .where((s) => s.isNotEmpty)
        .toList();
    if (segments.isEmpty) return packageName;

    final meaningful = segments.where((s) => !_genericSegments.contains(s.toLowerCase())).toList();
    final chosen = meaningful.isNotEmpty ? meaningful.last : segments.last;

    final words = chosen
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .split(RegExp(r'[_\-\s]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1));
    final result = words.join(' ');
    return result.isEmpty ? packageName : result;
  }
}
