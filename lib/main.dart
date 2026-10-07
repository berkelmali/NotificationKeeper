import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'presentation/screens/ios_fallback_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/vault_lock_screen.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/app_list_provider.dart';
import 'presentation/providers/stats_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/providers/app_registry.dart';
import 'presentation/providers/vault_provider.dart';
import 'presentation/theme/app_theme.dart';
import 'l10n/generated/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load settings before app starts
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

  // The vault must know whether it is locked before the first frame, or the
  // archive would flash on screen before the lock screen replaced it.
  final vaultProvider = VaultProvider();
  await vaultProvider.load();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AppListProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: vaultProvider),
        // App detection: real names and icons for every package the UI shows.
        ChangeNotifierProvider(create: (_) => AppRegistry()),
      ],
      child: const NotificationKeeperApp(),
    ),
  );
}

/// The app's navigator. The vault's lock sits above it, and opens screens on
/// it once it has stepped aside (a new PIN after "forgot PIN").
final _navigatorKey = GlobalKey<NavigatorState>();

class NotificationKeeperApp extends StatelessWidget {
  const NotificationKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'Notification Keeper',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: settings.themeMode,
          // New feature: multi-language support. locale: null means "follow
          // the device's system language" (falls back to English if the
          // device language isn't one of supportedLocales).
          locale: settings.appLocale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          // The vault (Settings > Security, off by default) locks the whole
          // app: it sits above the navigator, so it also covers any screen,
          // sheet or dialog left open, and unlocking returns to the same place.
          builder: Platform.isIOS
              ? null
              : (context, navigator) => VaultLockScreen(
                    navigatorKey: _navigatorKey,
                    child: navigator ?? const SizedBox.shrink(),
                  ),
          home: Platform.isIOS ? const IOSFallbackScreen() : const MainScreen(),
        );
      },
    );
  }
}
