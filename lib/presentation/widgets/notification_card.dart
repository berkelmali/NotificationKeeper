import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../domain/models/notification_model.dart';
import '../theme/app_colors.dart';
import 'app_icon_widget.dart';
import 'glass_card.dart';
import '../../l10n/generated/app_localizations.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismissed;
  final VoidCallback? onStarToggle;
  final int index;

  const NotificationCard({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismissed,
    this.onStarToggle,
    this.index = 0,
  });

  String _getAppShortName(String packageName) {
    final parts = packageName.split('.');
    if (parts.length >= 2) {
      return parts.last[0].toUpperCase() + parts.last.substring(1);
    }
    return packageName;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateTime.fromMillisecondsSinceEpoch(notification.timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    String timeStr;
    if (diff.inMinutes < 1) {
      timeStr = l10n.justNow;
    } else if (diff.inMinutes < 60) {
      timeStr = l10n.minutesAgo(diff.inMinutes);
    } else if (diff.inHours < 24) {
      timeStr = l10n.hoursAgo(diff.inHours);
    } else if (diff.inDays < 7) {
      timeStr = l10n.daysAgo(diff.inDays);
    } else {
      timeStr = DateFormat.MMMd(Localizations.localeOf(context).toString()).format(date);
    }

    final appName = _getAppShortName(notification.packageName);
    final hasTags = notification.tagList.isNotEmpty;

    Widget card = GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unread indicator dot
          Stack(
            children: [
              AppIconWidget(
                packageName: notification.packageName,
                appName: appName,
                size: 42,
                fontSize: 16,
              ),
              if (!notification.isRead)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.info,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title ?? l10n.noTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
                            ),
                      ),
                    ),
                    if (notification.isStarred)
                      GestureDetector(
                        onTap: onStarToggle,
                        child: const Icon(
                          Icons.star_rounded,
                          color: AppColors.warning,
                          size: 18,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  notification.content ?? l10n.noContent,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                // New feature: image attachment thumbnail
                if (notification.imagePath != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(notification.imagePath!),
                      height: 90,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.colorForPackage(
                                notification.packageName)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        appName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.colorForPackage(
                              notification.packageName),
                        ),
                      ),
                    ),
                    // Feature 3: Show first tag if exists
                    if (hasTags) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.tagColors[0].withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.label_rounded,
                              size: 10,
                              color: AppColors.tagColors[0],
                            ),
                            const SizedBox(width: 3),
                            Text(
                              notification.tagList.first,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.tagColors[0],
                              ),
                            ),
                            if (notification.tagList.length > 1)
                              Text(
                                ' +${notification.tagList.length - 1}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.tagColors[0].withValues(alpha: 0.7),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Feature 4 (Clone): Quick copy button
                    GestureDetector(
                      onTap: () {
                        final text = '${notification.title ?? ''}\n${notification.content ?? ''}';
                        Clipboard.setData(ClipboardData(text: text.trim()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                                const SizedBox(width: 6),
                                Text(l10n.copiedLabel, style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, right: 4),
                        child: Icon(
                          Icons.copy_rounded,
                          size: 14,
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onDismissed != null) {
      card = Dismissible(
        key: Key('notification_${notification.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismissed?.call(),
        background: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: const Icon(
            Icons.delete_outline_rounded,
            color: AppColors.error,
            size: 24,
          ),
        ),
        child: card,
      );
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50).clamp(0, 300)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: child,
          ),
        );
      },
      child: card,
    );
  }
}
