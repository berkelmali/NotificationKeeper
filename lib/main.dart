import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'presentation/screens/ios_fallback_screen.dart';
import 'presentation/screens/home_screen.dart';
import 'presentation/screens/biometric_lock_screen.dart';
import 'presentation/providers/notification_provider.dart';
import 'presentation/providers/app_list_provider.dart';
import 'presentation/providers/stats_provider.dart';
import 'presentation/providers/settings_provider.dart';
import 'presentation/theme/app_theme.dart';
import 'l10n/generated/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load settings before app starts
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();

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
      ],
      child: const NotificationKeeperApp(),
    ),
  );
}

class NotificationKeeperApp extends StatelessWidget {
  const NotificationKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return MaterialApp(
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
          home: Platform.isIOS
              ? const IOSFallbackScreen()
              // Merged from base.apk: optional Biometric Vault lock, opt-in
              // via Settings > Security. Off by default so existing users
              // aren't locked out unexpectedly.
              : (settings.biometricLockEnabled
                  ? const BiometricLockScreen(child: MainScreen())
                  : const MainScreen()),
        );
      },
    );
  }
}
