import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:app/main.dart';
import 'package:app/presentation/providers/notification_provider.dart';
import 'package:app/presentation/providers/app_list_provider.dart';
import 'package:app/presentation/providers/stats_provider.dart';
import 'package:app/presentation/providers/settings_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final settingsProvider = SettingsProvider();
    await tester.pumpWidget(
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
  });
}
