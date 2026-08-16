import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

/// Feature 3 (Unique): Tag management widget for notifications
class TagChips extends StatelessWidget {
  final List<String> tags;
  final VoidCallback? onAddTag;
  final Function(String)? onRemoveTag;
  final bool editable;

  const TagChips({
    super.key,
    required this.tags,
    this.onAddTag,
    this.onRemoveTag,
    this.editable = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...tags.asMap().entries.map((entry) {
          final index = entry.key;
          final tag = entry.value;
          final color = AppColors.tagColors[index % AppColors.tagColors.length];

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withValues(alpha: 0.4),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.label_rounded,
                  size: 12,
                  color: color,
                ),
                const SizedBox(width: 4),
                Text(
                  tag,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
                if (editable && onRemoveTag != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => onRemoveTag!(tag),
                    child: Icon(
                      Icons.close_rounded,
                      size: 12,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
        if (editable && onAddTag != null)
          GestureDetector(
            onTap: onAddTag,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceLight
                    : AppColors.cardLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? AppColors.cardBorder
                      : AppColors.cardBorderLight,
                  width: 0.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: 14,
                    color: isDark ? AppColors.textTertiary : AppColors.textSecondaryLight,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    l10n.addTagTitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textTertiary : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Dialog for adding a new tag
class AddTagDialog extends StatefulWidget {
  final List<String> existingTags;
  final List<String> suggestedTags;

  const AddTagDialog({
    super.key,
    required this.existingTags,
    this.suggestedTags = const ['Important', 'Work', 'Personal', 'Shopping', 'Social', 'News', 'Finance', 'Travel'],
  });

  @override
  State<AddTagDialog> createState() => _AddTagDialogState();
}

class _AddTagDialogState extends State<AddTagDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final availableSuggestions = widget.suggestedTags
        .where((t) => !widget.existingTags.contains(t))
        .toList();

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.label_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(l10n.addTagTitle),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: l10n.enterTagNameHint,
              prefixIcon: const Icon(Icons.label_outline_rounded),
            ),
            autofocus: true,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                Navigator.of(context).pop(value.trim());
              }
            },
          ),
          if (availableSuggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.suggestionsLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: availableSuggestions.map((tag) {
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(tag),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primaryStart.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primaryStart.withValues(alpha: 0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.primaryStart,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelAction),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          child: Text(l10n.addAction),
        ),
      ],
    );
  }
}
