import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_list_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';
import '../widgets/app_icon_widget.dart';
import '../widgets/shimmer_loading.dart';
import 'app_detail_screen.dart';
import '../../l10n/generated/app_localizations.dart';

class AppsScreen extends StatefulWidget {
  const AppsScreen({super.key});

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AppListProvider>(context, listen: false).fetchApps();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.navAppsLabel,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  Consumer<AppListProvider>(
                    builder: (context, provider, _) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primaryStart.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${provider.monitoredCount} / ${provider.totalCount} monitored',
                          style: const TextStyle(
                            color: AppColors.primaryStart,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Search ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: l10n.appsSearchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 20),
                          onPressed: () {
                            _searchController.clear();
                            Provider.of<AppListProvider>(context, listen: false)
                                .search('');
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  Provider.of<AppListProvider>(context, listen: false)
                      .search(value);
                  setState(() {});
                },
              ),
            ),
            const SizedBox(height: 12),

            // ─── View Mode Chips + Bulk Actions ───
            Consumer<AppListProvider>(
              builder: (context, provider, _) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _ViewModeChip(
                        label: l10n.filterAll,
                        isSelected: provider.viewMode == 'all',
                        onTap: () => provider.setViewMode('all'),
                      ),
                      const SizedBox(width: 8),
                      _ViewModeChip(
                        label: l10n.filterMonitored,
                        isSelected: provider.viewMode == 'monitored',
                        onTap: () => provider.setViewMode('monitored'),
                      ),
                      const SizedBox(width: 8),
                      _ViewModeChip(
                        label: l10n.filterOff,
                        isSelected: provider.viewMode == 'unmonitored',
                        onTap: () => provider.setViewMode('unmonitored'),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: Icon(
                          Icons.more_vert_rounded,
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textSecondaryLight,
                        ),
                        color: isDark ? AppColors.surfaceLight : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) {
                          if (value == 'select_all') {
                            provider.setAllMonitored(true);
                          } else if (value == 'deselect_all') {
                            provider.setAllMonitored(false);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'select_all',
                            child: Row(
                              children: [
                                const Icon(Icons.select_all_rounded, size: 20),
                                const SizedBox(width: 12),
                                Text(l10n.selectAllAction),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'deselect_all',
                            child: Row(
                              children: [
                                const Icon(Icons.deselect_rounded, size: 20),
                                const SizedBox(width: 12),
                                Text(l10n.deselectAllAction),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // ─── App List ───
            Expanded(
              child: Consumer<AppListProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const ShimmerLoading(itemHeight: 72);
                  }

                  if (provider.apps.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.apps_rounded,
                            size: 64,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            l10n.noAppsFound,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(color: AppColors.textTertiary),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.fetchApps(),
                    color: AppColors.primaryStart,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: provider.apps.length,
                      itemBuilder: (context, index) {
                        final app = provider.apps[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(
                              milliseconds:
                                  200 + (index * 30).clamp(0, 200)),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            return Opacity(
                              opacity: value,
                              child: Transform.translate(
                                offset: Offset(0, 15 * (1 - value)),
                                child: child,
                              ),
                            );
                          },
                          child: GlassCard(
                            // Feature 6 (Clone): Navigate to App Detail Screen on tap
                            onTap: app.notificationCount > 0
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AppDetailScreen(
                                          packageName: app.packageName,
                                          appName: app.appName,
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Hero(
                                  tag: 'app_icon_${app.packageName}',
                                  child: AppIconWidget(
                                    packageName: app.packageName,
                                    appName: app.appName,
                                    size: 42,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        app.appName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              app.packageName,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (app.notificationCount > 0) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets
                                                  .symmetric(
                                                  horizontal: 8,
                                                  vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.accent
                                                    .withValues(alpha: 0.15),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text(
                                                    '${app.notificationCount}',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: AppColors.accent,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 2),
                                                  const Icon(
                                                    Icons.chevron_right_rounded,
                                                    size: 12,
                                                    color: AppColors.accent,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: app.isMonitored,
                                  onChanged: (value) {
                                    provider.toggleApp(
                                        app.packageName, value);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewModeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewModeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryStart.withValues(alpha: 0.2)
              : (isDark ? AppColors.surfaceLight : AppColors.cardLight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryStart.withValues(alpha: 0.6)
                : (isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? AppColors.primaryStart
                : (isDark
                    ? AppColors.textSecondary
                    : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }
}
