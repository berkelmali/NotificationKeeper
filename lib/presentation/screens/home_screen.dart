import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import 'archive_screen.dart';
import 'apps_screen.dart';
import 'settings_screen.dart';
import 'permission_screen.dart';
import 'app_picker_screen.dart';
import '../widgets/custom_bottom_nav.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/services/notification_events.dart';
import '../providers/notification_provider.dart';
import '../providers/stats_provider.dart';
import '../providers/settings_provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final NotificationRepository _repo = NotificationRepository();
  bool _hasPermission = false;
  bool _isLoading = true;
  StreamSubscription<String>? _liveUpdates;
  Timer? _refreshTimer;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ArchiveScreen(),
    AppsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _liveUpdates?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
      // Back from WhatsApp & co.: what arrived meanwhile should already be
      // there. This used to need a cold start.
      _refreshData();
    } else if (state == AppLifecycleState.paused) {
      // Commit deletes still inside their undo window, in case Android kills
      // the process while the app is in the background.
      context.read<NotificationProvider>().flushPendingDeletes();
    }
  }
  
  /// Quiet reload of everything the archive and dashboard show. Bursts (a chat
  /// app re-posting several times a second) collapse into one reload.
  void _refreshData() {
    if (!_hasPermission || !mounted) return;
    _refreshTimer?.cancel();
    _refreshTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      context.read<NotificationProvider>().fetchNotifications(silent: true);
      context.read<StatsProvider>().fetchStats();
    });
  }

  /// Live updates while the app is open. Only started once access is granted,
  /// so there is nothing to listen to before that.
  void _startLiveUpdates() {
    _liveUpdates ??= NotificationEvents.stream.listen(
      (_) => _refreshData(),
      onError: (Object e) => debugPrint('Live updates unavailable: $e'),
    );
  }

  Future<bool> _checkPermission() async {
    final enabled = await _repo.isServiceEnabled();
    if (enabled) _startLiveUpdates();
    if (mounted) {
      setState(() {
        _hasPermission = enabled;
        _isLoading = false;
      });
    }
    return enabled;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }
      
    if (!_hasPermission) {
      return PermissionScreen(onPermissionGranted: _checkPermission);
    }

    // First run: nothing is kept until some app is switched on, so ask once.
    if (!context.select<SettingsProvider, bool>((s) => s.appPickerDone)) {
      return const AppPickerScreen();
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      extendBody: true,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
