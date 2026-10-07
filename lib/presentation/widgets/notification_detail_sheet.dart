import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../domain/models/notification_model.dart';
import '../theme/app_colors.dart';
import '../providers/notification_provider.dart';
import '../screens/photo_viewer_screen.dart';
import 'app_icon_widget.dart';
import 'tag_chips.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/app_registry.dart';

class NotificationDetailSheet extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onStarToggle;
  final VoidCallback? onDelete;

  const NotificationDetailSheet({
    super.key,
    required this.notification,
    this.onStarToggle,
    this.onDelete,
  });


  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = DateTime.fromMillisecondsSinceEpoch(notification.timestamp);
    final formattedDate = DateFormat(
      'EEEE, MMM d, yyyy • HH:mm',
      Localizations.localeOf(context).toString(),
    ).format(date);
    final appName = context.appLabel(notification.packageName);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardBorder : AppColors.cardBorderLight,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    AppIconWidget(
                      packageName: notification.packageName,
                      appName: appName,
                      size: 48,
                      fontSize: 20,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            notification.packageName,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Read indicator
                    if (!notification.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.info,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.info.withValues(alpha: 0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // New feature A: Recall Radar. Explained in full here rather
                // than as a bare badge - "the sender deleted this" is a claim
                // worth spelling out, including that it is an inference.
                if (notification.isRecalled) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.warning.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.undo_rounded,
                                size: 16, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Text(
                              l10n.recalledBadge,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: AppColors.warning,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              l10n.recalledAtLabel(
                                DateFormat.Hm(Localizations.localeOf(context).toString())
                                    .format(DateTime.fromMillisecondsSinceEpoch(
                                        notification.recalledAt!)),
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.recalledExplanation,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                height: 1.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Title
                if (notification.title != null) ...[
                  Text(
                    notification.title!,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Content
                if (notification.content != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.cardDark
                          : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? AppColors.cardBorder
                            : AppColors.cardBorderLight,
                      ),
                    ),
                    child: Text(
                      notification.content!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Photo vault: tap the photo to open it full screen. The old
                // viewer was a dialog that closed on any tap, which fought with
                // pinch-zoom; this one zooms, shares, and says when the sender
                // deleted the message.
                if (notification.hasImage) ...[
                  Semantics(
                    button: true,
                    label: l10n.sharePhoto,
                    child: GestureDetector(
                      onTap: () => PhotoViewerScreen.open(context, notification),
                      child: Hero(
                        tag: PhotoViewerScreen.heroTag(notification),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(notification.imagePath!),
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                            cacheWidth: 1080,
                            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Sub text
                if (notification.subText != null) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notification.subText!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Timestamp
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formattedDate,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),

                // Category
                if (notification.category != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.category_rounded,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.categoryLabel(notification.category!),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],

                // ─── Tags (Feature 3: Unique - Tagging) ───
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.label_rounded,
                      size: 16,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      l10n.tagsLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TagChips(
                  tags: notification.tagList,
                  editable: true,
                  onAddTag: () async {
                    final tag = await showDialog<String>(
                      context: context,
                      builder: (_) => AddTagDialog(
                        existingTags: notification.tagList,
                        suggestedTags: [
                          l10n.tagImportant,
                          l10n.tagWork,
                          l10n.tagPersonal,
                          l10n.tagShopping,
                          l10n.tagSocial,
                          l10n.tagNews,
                          l10n.tagFinance,
                          l10n.tagTravel,
                        ],
                      ),
                    );
                    if (tag != null && context.mounted) {
                      Provider.of<NotificationProvider>(context, listen: false)
                          .addTag(notification.id, tag);
                    }
                  },
                  onRemoveTag: (tag) {
                    Provider.of<NotificationProvider>(context, listen: false)
                        .removeTag(notification.id, tag);
                  },
                ),

                const SizedBox(height: 24),

                // Action buttons - 3 buttons: Star, Copy, Delete
                Row(
                  children: [
                    // Star button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onStarToggle,
                        icon: Icon(
                          notification.isStarred
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 20,
                          color: notification.isStarred
                              ? AppColors.warning
                              : null,
                        ),
                        label: Text(
                          notification.isStarred ? l10n.unstarAction : l10n.starAction,
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.cardBorder
                                : AppColors.cardBorderLight,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Feature 4 (Clone from Notification History Log): Copy button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final text = '${notification.title ?? ''}\n${notification.content ?? ''}';
                          Clipboard.setData(ClipboardData(text: text.trim()));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18),
                                  const SizedBox(width: 8),
                                  Text(l10n.copiedToClipboard),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 20,
                          color: AppColors.accent,
                        ),
                        label: Text(
                          l10n.copyAction,
                          style: const TextStyle(color: AppColors.accent),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: AppColors.accent.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Delete button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onDelete?.call();
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: AppColors.error,
                        ),
                        label: Text(
                          l10n.deleteAction,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
