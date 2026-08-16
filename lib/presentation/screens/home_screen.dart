import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'archive_screen.dart';
import 'apps_screen.dart';
import 'settings_screen.dart';
import 'permission_screen.dart';
import '../widgets/custom_bottom_nav.dart';
import '../../data/repositories/notification_repository.dart';

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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }
  
  Future<bool> _checkPermission() async {
    final enabled = await _repo.isServiceEnabled();
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
