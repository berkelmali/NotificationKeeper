import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/stats_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_counter.dart';
import '../widgets/app_icon_widget.dart';
import '../widgets/notification_card.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/hourly_heatmap.dart';
import '../../l10n/generated/app_localizations.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final statsProvider = Provider.of<StatsProvider>(context, listen: false);
      final notifProvider = Provider.of<NotificationProvider>(context, listen: false);
      statsProvider.fetchStats();
      notifProvider.fetchNotifications().then((_) {
        // Compute hourly activity from all notifications
        statsProvider.computeHourlyFromNotifications(notifProvider.allNotifications);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Consumer2<StatsProvider, NotificationProvider>(
          builder: (context, statsProvider, notifProvider, child) {
            if (statsProvider.isLoading && statsProvider.stats == null) {
              return const ShimmerLoading(itemCount: 5, itemHeight: 100);
            }

            final stats = statsProvider.stats;
            final recentNotifs = notifProvider.allNotifications.take(5).toList();

            return RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  statsProvider.fetchStats(),
                  notifProvider.fetchNotifications(),
                ]);
                statsProvider.computeHourlyFromNotifications(notifProvider.allNotifications);
              },
              color: AppColors.primaryStart,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 100),
                children: [
                  // ─── Header with Quiet Hours indicator ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.dashboardTitle,
                                style: Theme.of(context).textTheme.headlineLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.dashboardSubtitle,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        // Quiet Hours indicator
                        Consumer<SettingsProvider>(
                          builder: (context, settings, _) {
                            if (!settings.quietHoursEnabled) return const SizedBox.shrink();
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: settings.isQuietHoursActive
                                    ? AppColors.warning.withValues(alpha: 0.15)
                                    : AppColors.success.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: settings.isQuietHoursActive
                                      ? AppColors.warning.withValues(alpha: 0.4)
                                      : AppColors.success.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    settings.isQuietHoursActive
                                        ? Icons.do_not_disturb_on_rounded
                                        : Icons.notifications_active_rounded,
                                    size: 14,
                                    color: settings.isQuietHoursActive
                                        ? AppColors.warning
                                        : AppColors.success,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    settings.isQuietHoursActive ? l10n.quietHoursBadge : l10n.quietHoursActiveBadge,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: settings.isQuietHoursActive
                                          ? AppColors.warning
                                          : AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── Stats Cards Row ───
                  SizedBox(
                    height: 120,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _StatCard(
                          title: l10n.statToday,
                          value: stats?.todayCount ?? 0,
                          icon: Icons.today_rounded,
                          gradient: AppColors.primaryGradient,
                        ),
                        _StatCard(
                          title: l10n.statThisWeek,
                          value: stats?.weekCount ?? 0,
                          icon: Icons.date_range_rounded,
                          gradient: AppColors.accentGradient,
                        ),
                        _StatCard(
                          title: l10n.statTotal,
                          value: stats?.totalCount ?? 0,
                          icon: Icons.notifications_rounded,
                          gradient: const LinearGradient(
                            colors: [AppColors.warning, Color(0xFFFF9F43)],
                          ),
                        ),
                        _StatCard(
                          title: l10n.statUnread,
                          value: notifProvider.allNotifications.where((n) => !n.isRead).length,
                          icon: Icons.mark_email_unread_rounded,
                          gradient: const LinearGradient(
                            colors: [AppColors.info, Color(0xFF0984E3)],
                          ),
                        ),
                        // ─── Merged from base.apk (com.example.fluter) ───
                        _StatCard(
                          title: l10n.statCodesToday,
                          value: stats?.otpCountToday ?? 0,
                          icon: Icons.vpn_key_rounded,
                          gradient: const LinearGradient(
                            colors: [AppColors.success, Color(0xFF00A382)],
                          ),
                        ),
                        _StatCard(
                          title: l10n.statPriorityToday,
                          value: stats?.priorityCountToday ?? 0,
                          icon: Icons.radar_rounded,
                          gradient: const LinearGradient(
                            colors: [AppColors.error, Color(0xFFE84393)],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if ((stats?.quietHoursSkippedToday ?? 0) > 0) ...[
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Icon(Icons.do_not_disturb_on_rounded, size: 14, color: AppColors.textTertiary),
                          const SizedBox(width: 6),
                          Text(
                            '${stats!.quietHoursSkippedToday} notification${stats.quietHoursSkippedToday == 1 ? '' : 's'} skipped during Quiet Hours today',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textTertiary,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // ─── Hourly Activity Heatmap (Feature 2: Unique) ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Text(
                          l10n.activityHeatmap,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primaryStart.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '24h',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryStart,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: HourlyHeatmap(
                      hourlyData: statsProvider.hourlyActivity,
                      peakHour: statsProvider.peakHour,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Weekly Chart ───
                  if (stats != null && stats.dailyCounts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        l10n.weeklyTrend,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                      child: SizedBox(
                        height: 180,
                        child: _WeeklyChart(dailyCounts: stats.dailyCounts),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // ─── Top Apps ───
                  if (stats != null && stats.topApps.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        l10n.topApps,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...stats.topApps.map((entry) {
                      final appName = _getAppShortName(entry.key);
                      final maxCount = stats.topApps.first.value;
                      final ratio = maxCount > 0 ? entry.value / maxCount : 0.0;

                      return GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            AppIconWidget(
                              packageName: entry.key,
                              appName: appName,
                              size: 36,
                              fontSize: 14,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: ratio,
                                      backgroundColor: isDark
                                          ? AppColors.surfaceLight
                                          : AppColors.cardLight,
                                      valueColor: AlwaysStoppedAnimation(
                                        AppColors.colorForPackage(entry.key),
                                      ),
                                      minHeight: 6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${entry.value}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.colorForPackage(entry.key),
                                  ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // ─── Recent Notifications ───
                  if (recentNotifs.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.recentSectionTitle,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          TextButton(
                            onPressed: () {
                              // Navigate to archive — handled by parent's tab switch
                            },
                            child: Text(l10n.seeAll),
                          ),
                        ],
                      ),
                    ),
                    ...List.generate(recentNotifs.length, (index) {
                      return NotificationCard(
                        notification: recentNotifs[index],
                        index: index,
                      );
                    }),
                  ],

                  if (stats?.totalCount == 0 && recentNotifs.isEmpty)
                    SizedBox(
                      height: 300,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 64,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              l10n.emptyStateTitle,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    color: AppColors.textTertiary,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.emptyStateSubtitle,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _getAppShortName(String packageName) {
    final parts = packageName.split('.');
    if (parts.length >= 2) {
      return parts.last[0].toUpperCase() + parts.last.substring(1);
    }
    return packageName;
  }
}

// ─── Stat Card Widget ───
class _StatCard extends StatelessWidget {
  final String title;
  final int value;
  final IconData icon;
  final Gradient gradient;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (gradient as LinearGradient).colors.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const Spacer(),
          AnimatedCounter(
            value: value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Weekly Bar Chart ───
class _WeeklyChart extends StatelessWidget {
  final List dailyCounts;

  const _WeeklyChart({required this.dailyCounts});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxY = dailyCounts.fold<double>(
      0,
      (max, dc) => dc.count > max ? dc.count.toDouble() : max,
    );

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY > 0 ? maxY * 1.2 : 10,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => isDark ? AppColors.surfaceLight : Colors.white,
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()}',
                TextStyle(
                  color: AppColors.primaryStart,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= dailyCounts.length) {
                  return const SizedBox.shrink();
                }
                final day = DateFormat('E').format(dailyCounts[index].date);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    day,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textTertiary
                          : AppColors.textSecondaryLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
              reservedSize: 28,
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(dailyCounts.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: dailyCounts[index].count.toDouble(),
                gradient: AppColors.primaryGradient,
                width: 24,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(8),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
