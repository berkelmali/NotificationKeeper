import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/notification_card.dart';
import '../widgets/notification_detail_sheet.dart';
import '../widgets/shimmer_loading.dart';
import '../widgets/date_header.dart';
import '../widgets/recent_codes_widget.dart';
import '../../domain/models/notification_model.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/app_registry.dart';

class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSearchHistory = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).fetchNotifications();
    });
    _searchFocusNode.addListener(() {
      setState(() {
        _showSearchHistory =
            _searchFocusNode.hasFocus && _searchController.text.isEmpty;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
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
      final date = DateTime.fromMillisecondsSinceEpoch(
        notifications[i].timestamp,
      );
      final label = _getDateLabel(date);
      if (label != lastLabel) {
        items.add(label); // String = date header
        lastLabel = label;
      }
      items.add(notifications[i]); // NotificationModel = card
    }
    return items;
  }

  void _showDetail(NotificationModel notification) {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
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
              onStarToggle: () {
                p.toggleStar(notification.id);
              },
              onDelete: () => _deleteWithUndo(p, notification, l10n),
            );
          },
        ),
      ),
    );
  }

  /// Deletes with a real undo: the row leaves the list now and the database
  /// only when the snackbar's window closes.
  void _deleteWithUndo(
    NotificationProvider provider,
    NotificationModel notification,
    AppLocalizations l10n,
  ) {
    provider.deleteWithUndo(notification.id);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.notificationDeleted),
        duration: NotificationProvider.undoWindow,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: l10n.undoAction,
          textColor: AppColors.accent,
          onPressed: () => provider.undoDelete(notification.id),
        ),
      ),
    );
  }

  /// Feature 4 (Clone): Copy notification content to clipboard
  void _copyNotification(NotificationModel notification) {
    final l10n = AppLocalizations.of(context)!;
    final text = '${notification.title ?? ''}\n${notification.content ?? ''}';
    Clipboard.setData(ClipboardData(text: text.trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(l10n.copiedToClipboard),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
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
                    l10n.archiveTitle,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  // Notification count badge
                  Consumer<NotificationProvider>(
                    builder: (context, provider, _) {
                      final count = provider.notifications.length;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryStart.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: AppColors.primaryStart,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ─── Search Bar with History ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      decoration: InputDecoration(
                        hintText: l10n.searchHint,
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  Provider.of<NotificationProvider>(
                                    context,
                                    listen: false,
                                  ).search('');
                                  setState(() {
                                    _showSearchHistory =
                                        _searchFocusNode.hasFocus;
                                  });
                                },
                              )
                            : null,
                      ),
                      onChanged: (value) {
                        Provider.of<NotificationProvider>(
                          context,
                          listen: false,
                        ).search(value);
                        setState(() {
                          _showSearchHistory = false;
                        });
                      },
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          Provider.of<SettingsProvider>(
                            context,
                            listen: false,
                          ).addSearchQuery(value.trim());
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // New feature: date-range filter
                  Consumer<NotificationProvider>(
                    builder: (context, provider, _) {
                      final isActive = provider.dateRange != null;
                      return Container(
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.primaryStart.withValues(alpha: 0.15)
                              : (isDark
                                    ? AppColors.cardDark
                                    : AppColors.cardLight),
                          borderRadius: BorderRadius.circular(12),
                          border: isActive
                              ? Border.all(color: AppColors.primaryStart)
                              : null,
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.date_range_rounded,
                            color: isActive ? AppColors.primaryStart : null,
                          ),
                          tooltip: l10n.filterByDateRange,
                          onPressed: () async {
                            final now = DateTime.now();
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(now.year - 5),
                              lastDate: now,
                              initialDateRange: provider.dateRange,
                            );
                            if (picked != null) {
                              provider.setDateRange(picked);
                            }
                          },
                          onLongPress: isActive
                              ? () => provider.setDateRange(null)
                              : null,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // New feature: active date-range chip (long-press the calendar icon to clear)
            Consumer<NotificationProvider>(
              builder: (context, provider, _) {
                if (provider.dateRange == null) return const SizedBox.shrink();
                final r = provider.dateRange!;
                String fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InputChip(
                      label: Text('${fmt(r.start)} – ${fmt(r.end)}'),
                      onDeleted: () => provider.setDateRange(null),
                      avatar: const Icon(Icons.date_range_rounded, size: 16),
                    ),
                  ),
                );
              },
            ),

            // ─── Feature 1 (Unique): Search History Dropdown ───
            if (_showSearchHistory)
              Consumer<SettingsProvider>(
                builder: (context, settings, _) {
                  if (settings.searchHistory.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                      border: Border.all(
                        color: isDark
                            ? AppColors.cardBorder
                            : AppColors.cardBorderLight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                          child: Row(
                            children: [
                              Text(
                                l10n.recentSearches,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textTertiary
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => settings.clearSearchHistory(),
                                child: Text(
                                  l10n.clearAction,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ),
                        ...settings.searchHistory.map((query) {
                          return InkWell(
                            onTap: () {
                              _searchController.text = query;
                              Provider.of<NotificationProvider>(
                                context,
                                listen: false,
                              ).search(query);
                              _searchFocusNode.unfocus();
                              setState(() => _showSearchHistory = false);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.history_rounded,
                                    size: 16,
                                    color: isDark
                                        ? AppColors.textTertiary
                                        : AppColors.textSecondaryLight,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      query,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        settings.removeSearchQuery(query),
                                    child: Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                      color: isDark
                                          ? AppColors.textTertiary
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 12),

            // ─── Filter Chips (includes tags) ───
            Consumer<NotificationProvider>(
              builder: (context, provider, _) {
                return SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // BUG FIX: these four chip labels were the last hardcoded
                      // English strings in the archive - they stayed in English
                      // even with the app switched to Turkish.
                      _FilterChip(
                        label: l10n.filterAll,
                        isSelected: provider.filterMode == 'all',
                        onTap: () {
                          provider.setFilterMode('all');
                          provider.filterByTag(null);
                        },
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: '⭐ ${l10n.statStarred}',
                        isSelected: provider.filterMode == 'starred',
                        onTap: () => provider.setFilterMode('starred'),
                      ),
                      const SizedBox(width: 8),
                      _FilterChip(
                        label: l10n.statUnread,
                        isSelected: provider.filterMode == 'unread',
                        onTap: () => provider.setFilterMode('unread'),
                      ),
                      const SizedBox(width: 8),
                      // Feature 3: Tagged filter
                      _FilterChip(
                        label: '🏷️ ${l10n.filterTagged}',
                        isSelected: provider.filterMode == 'tagged',
                        onTap: () => provider.setFilterMode('tagged'),
                      ),
                      const SizedBox(width: 8),
                      // New feature A: Recall Radar. Only offered once something
                      // has actually been withdrawn, so it doesn't sit there as a
                      // permanently empty filter.
                      // Photo vault: every kept picture in one place, offered as
                      // soon as the archive holds at least one.
                      if (provider.allNotifications.any((n) => n.hasImage)) ...[
                        _FilterChip(
                          label: '📷 ${l10n.filterPhotos}',
                          isSelected: provider.filterMode == 'photos',
                          color: AppColors.accent,
                          onTap: () => provider.setFilterMode('photos'),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (provider.allNotifications.any(
                        (n) => n.isRecalled,
                      )) ...[
                        _FilterChip(
                          label: '↩️ ${l10n.filterRecalled}',
                          isSelected: provider.filterMode == 'recalled',
                          color: AppColors.warning,
                          onTap: () => provider.setFilterMode('recalled'),
                        ),
                        const SizedBox(width: 8),
                      ],
                      // Tag-specific filters
                      ...provider.allTags.map((tag) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: '#$tag',
                            isSelected: provider.selectedTag == tag,
                            color:
                                AppColors.tagColors[provider.allTags.indexOf(
                                      tag,
                                    ) %
                                    AppColors.tagColors.length],
                            onTap: () {
                              provider.filterByTag(
                                provider.selectedTag == tag ? null : tag,
                              );
                            },
                          ),
                        );
                      }),
                      // Separator
                      if (provider.allTags.isNotEmpty &&
                          provider.uniqueApps.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 1,
                          height: 24,
                          color: isDark
                              ? AppColors.cardBorder
                              : AppColors.cardBorderLight,
                        ),
                      // App filter chips
                      ...provider.uniqueApps.take(5).map((pkg) {
                        final name = context.appLabel(pkg);
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _FilterChip(
                            label: name,
                            isSelected: provider.selectedApp == pkg,
                            color: AppColors.colorForPackage(pkg),
                            onTap: () {
                              provider.filterByApp(
                                provider.selectedApp == pkg ? null : pkg,
                              );
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // ─── Recent Codes (merged from base.apk) ───
            Consumer<NotificationProvider>(
              builder: (context, provider, child) {
                return RecentCodesWidget(notifications: provider.notifications);
              },
            ),

            // ─── Notification List ───
            Expanded(
              child: Consumer<NotificationProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const ShimmerLoading();
                  }

                  if (provider.notifications.isEmpty) {
                    // Pull-to-refresh has to work exactly here - an empty archive
                    // is the moment someone wants to check again - so the empty
                    // state sits inside an always-scrollable view.
                    return RefreshIndicator(
                      onRefresh: () =>
                          provider.fetchNotifications(silent: true),
                      color: AppColors.primaryStart,
                      child: LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
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
                                    l10n.noNotificationsFound,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: AppColors.textTertiary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    provider.searchQuery.isNotEmpty
                                        ? l10n.tryDifferentSearchTerm
                                        : l10n.capturedNotificationsAppearHere,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final grouped = _buildGroupedList(provider.notifications);

                  return RefreshIndicator(
                    onRefresh: () => provider.fetchNotifications(),
                    color: AppColors.primaryStart,
                    child: ListView.builder(
                      controller: _scrollController,
                      // Without this a list shorter than the screen cannot scroll,
                      // so the pull gesture never reaches RefreshIndicator.
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: grouped.length,
                      itemBuilder: (context, index) {
                        final item = grouped[index];
                        if (item is String) {
                          return DateHeader(label: item);
                        }
                        final notification = item as NotificationModel;
                        return GestureDetector(
                          onLongPress: () => _copyNotification(notification),
                          child: NotificationCard(
                            notification: notification,
                            index: index,
                            onTap: () => _showDetail(notification),
                            onDismissed: () =>
                                _deleteWithUndo(provider, notification, l10n),
                            onStarToggle: () {
                              provider.toggleStar(notification.id);
                            },
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

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = color ?? AppColors.primaryStart;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.2)
              : (isDark ? AppColors.cardDark : AppColors.cardLight),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? activeColor.withValues(alpha: 0.6)
                : (isDark ? AppColors.cardBorder : AppColors.cardBorderLight),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected
                ? activeColor
                : (isDark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight),
          ),
        ),
      ),
    );
  }
}
