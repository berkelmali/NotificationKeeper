import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/models/notification_model.dart';
import '../../domain/models/app_info_model.dart';
import '../theme/app_colors.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_detail_sheet.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/date_header.dart';
import '../widgets/app_icon_widget.dart';
import '../providers/notification_provider.dart';
import '../providers/app_list_provider.dart';
import '../../l10n/generated/app_localizations.dart';

/// Feature 6 (Clone from Past Notifications): App-specific notification detail page
/// Shows all notifications from a single app with stats and timeline
class AppDetailScreen extends StatefulWidget {
  final String packageName;
  final String appName;

  const AppDetailScreen({
    super.key,
    required this.packageName,
    required this.appName,
  });

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen>
    with SingleTickerProviderStateMixin {
  final NotificationRepository _repo = NotificationRepository();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _loadNotifications();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      _notifications = await _repo.getNotificationsByApp(widget.packageName);
    } catch (e) {
      debugPrint("Error loading app notifications: $e");
    }
    setState(() => _isLoading = false);
    _animController.forward();
  }

  String _getDateLabel(DateTime date) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return l10n.dateGroupToday;
    if (dateOnly == yesterday) return l10n.dateGroupYesterday;
    if (now.difference(date).inDays < 7) return l10n.dateGroupThisWeek;
    if (now.difference(date).inDays < 30) return l10n.dateGroupThisMonth;
    return l10n.dateGroupOlder;
  }

  List<dynamic> _buildGroupedList(List<NotificationModel> notifications) {
    final List<dynamic> items = [];
    String? lastLabel;

    for (var i = 0; i < notifications.length; i++) {
      final date = DateTime.fromMillisecondsSinceEpoch(notifications[i].timestamp);
      final label = _getDateLabel(date);
      if (label != lastLabel) {
        items.add(label);
        lastLabel = label;
      }
      items.add(notifications[i]);
    }
    return items;
  }

  void _showDetail(NotificationModel notification) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    provider.markAsRead(notification.id);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: provider,
        child: Consumer<NotificationProvider>(
          builder: (context, p, _) {
            final updated = p.allNotifications
                .where((n) => n.id == notification.id)
                .firstOrNull;
            return NotificationDetailSheet(
              notification: updated ?? notification,
              onStarToggle: () => p.toggleStar(notification.id),
              onDelete: () {
                p.deleteNotification(notification.id);
                _notifications.removeWhere((n) => n.id == notification.id);
                setState(() {});
              },
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = AppColors.colorForPackage(widget.packageName);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── App Bar with Hero ───
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isDark ? Colors.black : Colors.white).withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_rounded, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            // New feature: per-app temporary snooze
            actions: [
              Consumer<AppListProvider>(
                builder: (context, appList, _) {
                  AppInfoModel? current;
                  try {
                    current = appList.allApps.firstWhere((a) => a.packageName == widget.packageName);
                  } catch (_) {
                    current = null;
                  }
                  final isSnoozed = current?.isSnoozed ?? false;

                  return PopupMenuButton<int>(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isSnoozed ? AppColors.warning : (isDark ? Colors.black : Colors.white))
                            .withValues(alpha: isSnoozed ? 0.25 : 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isSnoozed ? Icons.snooze_rounded : Icons.notifications_paused_outlined,
                        size: 20,
                        color: isSnoozed ? AppColors.warning : null,
                      ),
                    ),
                    tooltip: isSnoozed ? l10n.snoozedLabel : l10n.snoozeTooltip,
                    onSelected: (minutes) {
                      if (minutes == -1) {
                        appList.unsnoozeApp(widget.packageName);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.appUnsnoozed(widget.appName))),
                        );
                      } else {
                        appList.snoozeApp(widget.packageName, minutes);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.appSnoozed(widget.appName))),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 60, child: Text(l10n.snooze1Hour)),
                      PopupMenuItem(value: 480, child: Text(l10n.snooze8Hours)),
                      PopupMenuItem(value: 1440, child: Text(l10n.snooze24Hours)),
                      if (isSnoozed) PopupMenuItem(value: -1, child: Text(l10n.cancelSnooze)),
                    ],
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.3),
                      isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Hero(
                        tag: 'app_icon_${widget.packageName}',
                        child: AppIconWidget(
                          packageName: widget.packageName,
                          appName: widget.appName,
                          size: 64,
                          fontSize: 26,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.appName,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.packageName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ─── Stats Row ───
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    _MiniStat(
                      label: l10n.statTotal,
                      value: '${_notifications.length}',
                      icon: Icons.notifications_rounded,
                      color: color,
                    ),
                    const SizedBox(width: 12),
                    _MiniStat(
                      label: l10n.statToday,
                      value: '$_todayCount',
                      icon: Icons.today_rounded,
                      color: AppColors.accent,
                    ),
                    const SizedBox(width: 12),
                    _MiniStat(
                      label: l10n.statStarred,
                      value: '$_starredCount',
                      icon: Icons.star_rounded,
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Notification List ───
          if (_isLoading)
            const SliverFillRemaining(
              child: ShimmerLoading(),
            )
          else if (_notifications.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noNotifications,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: AppColors.textTertiary,
                          ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final grouped = _buildGroupedList(_notifications);
                  if (index >= grouped.length) return null;

                  final item = grouped[index];
                  if (item is String) {
                    return DateHeader(label: item);
                  }
                  final notification = item as NotificationModel;
                  return NotificationCard(
                    notification: notification,
                    index: index,
                    onTap: () => _showDetail(notification),
                    onDismissed: () {
                      final provider = Provider.of<NotificationProvider>(context, listen: false);
                      provider.deleteNotification(notification.id);
                      _notifications.removeWhere((n) => n.id == notification.id);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.notificationDeleted),
                          action: SnackBarAction(
                            label: l10n.undoAction,
                            textColor: AppColors.accent,
                            onPressed: () => _loadNotifications(),
                          ),
                        ),
                      );
                    },
                    onStarToggle: () {
                      Provider.of<NotificationProvider>(context, listen: false)
                          .toggleStar(notification.id);
                    },
                  );
                },
                childCount: _buildGroupedList(_notifications).length,
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  int get _todayCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _notifications.where((n) {
      final date = DateTime.fromMillisecondsSinceEpoch(n.timestamp);
      return date.isAfter(today);
    }).length;
  }

  int get _starredCount {
    return _notifications.where((n) => n.isStarred).length;
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.1 : 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.textTertiary : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
