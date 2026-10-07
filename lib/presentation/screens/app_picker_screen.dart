import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../data/repositories/notification_repository.dart';
import '../../domain/apps/known_apps.dart';
import '../../domain/models/app_info_model.dart';
import '../../l10n/generated/app_localizations.dart';
import '../providers/app_list_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/app_icon_widget.dart';

/// First run, right after notification access is granted: which apps should
/// be kept? The listener only keeps apps that are switched on, and nothing
/// was on until someone found the Apps tab - so a new archive stayed empty and
/// the app looked broken.
///
/// Chat apps and the phone's own SMS app start ticked. Anyone already keeping
/// an app (an update from before this step existed) never sees it. Answering
/// or skipping sets [SettingsProvider.appPickerDone], which is what moves the
/// app on.
class AppPickerScreen extends StatefulWidget {
  final NotificationRepository? repository;

  const AppPickerScreen({super.key, this.repository});

  /// The apps ticked to begin with: chat apps from the verified table, plus
  /// the phone's default SMS app - whatever its brand - for codes.
  static Set<String> suggested(Iterable<AppInfoModel> apps, String? smsPackage) {
    return {
      for (final app in apps)
        if (KnownApps.isMessaging(app.packageName) || app.packageName == smsPackage) app.packageName,
    };
  }

  @override
  State<AppPickerScreen> createState() => _AppPickerScreenState();
}

class _AppPickerScreenState extends State<AppPickerScreen> {
  late final NotificationRepository _repository = widget.repository ?? NotificationRepository();

  /// Null while loading.
  List<AppInfoModel>? _apps;
  Set<String> _suggested = const {};
  final Set<String> _selected = {};
  String? _smsPackage;
  String _query = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // After the first frame: loading notifies the app list, which must not
    // happen while this screen is still being built.
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final appList = context.read<AppListProvider>();
    final settings = context.read<SettingsProvider>();
    await appList.fetchApps();
    final sms = await _repository.getDefaultSmsPackage();
    if (!mounted) return;

    final apps = appList.allApps;
    if (apps.any((app) => app.isMonitored)) {
      // Chosen before this step existed: nothing to ask.
      await settings.setAppPickerDone(true);
      return;
    }

    final suggested = AppPickerScreen.suggested(apps, sms);
    final sorted = [...apps]
      ..sort((a, b) {
        final aFirst = suggested.contains(a.packageName);
        final bFirst = suggested.contains(b.packageName);
        if (aFirst != bFirst) return aFirst ? -1 : 1;
        return a.appName.toLowerCase().compareTo(b.appName.toLowerCase());
      });
    setState(() {
      _apps = sorted;
      _smsPackage = sms;
      _suggested = suggested;
      _selected
        ..clear()
        ..addAll(suggested);
    });
  }

  void _toggle(String packageName) {
    HapticFeedback.selectionClick();
    setState(() {
      if (!_selected.remove(packageName)) _selected.add(packageName);
    });
  }

  Future<void> _keep() async {
    final appList = context.read<AppListProvider>();
    final settings = context.read<SettingsProvider>();
    HapticFeedback.mediumImpact();
    setState(() => _saving = true);
    await appList.monitorApps(_selected);
    await settings.setAppPickerDone(true);
  }

  Future<void> _skip() => context.read<SettingsProvider>().setAppPickerDone(true);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final apps = _apps;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : null,
          color: isDark ? null : AppColors.backgroundLight,
        ),
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 300),
            child: apps == null
                ? const Center(key: ValueKey('loading'), child: CircularProgressIndicator())
                : _buildPicker(context, apps, isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildPicker(BuildContext context, List<AppInfoModel> apps, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    final query = _query.trim().toLowerCase();
    final visible = query.isEmpty
        ? apps
        : apps
              .where((a) => a.appName.toLowerCase().contains(query) || a.packageName.toLowerCase().contains(query))
              .toList();
    final suggested = visible.where((a) => _suggested.contains(a.packageName)).toList();
    final others = visible.where((a) => !_suggested.contains(a.packageName)).toList();
    final count = _selected.length;

    return Column(
      key: const ValueKey('picker'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryStart.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.checklist_rounded, color: AppColors.primaryStart, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.appPickerTitle,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.appPickerSubtitle,
                style: TextStyle(height: 1.45, color: isDark ? AppColors.textSecondary : AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: l10n.appsSearchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        Expanded(
          // Rows paint their tint and ripple on the nearest Material, which
          // would otherwise be the Scaffold underneath the gradient.
          child: Material(
            type: MaterialType.transparency,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              children: [
                if (suggested.isNotEmpty) ...[
                  _SectionLabel(text: l10n.appPickerSuggested),
                  for (final app in suggested) _row(app, l10n, isDark),
                ],
                if (others.isNotEmpty) ...[
                  _SectionLabel(text: l10n.appPickerOthers),
                  for (final app in others) _row(app, l10n, isDark),
                ],
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
          child: Column(
            children: [
              AnimatedOpacity(
                opacity: count == 0 ? 0.5 : 1,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryStart.withValues(alpha: count == 0 ? 0 : 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: count == 0 || _saving ? null : _keep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : Text(
                            count == 0 ? l10n.appPickerNone : l10n.appPickerKeep(count),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _saving ? null : _skip,
                child: Text(
                  l10n.appPickerSkip,
                  style: TextStyle(color: isDark ? AppColors.textTertiary : AppColors.textSecondaryLight),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(AppInfoModel app, AppLocalizations l10n, bool isDark) {
    final selected = _selected.contains(app.packageName);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: CheckboxListTile(
        value: selected,
        onChanged: _saving ? null : (_) => _toggle(app.packageName),
        secondary: AppIconWidget(packageName: app.packageName, appName: app.appName, size: 40),
        title: Text(app.appName, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: app.packageName == _smsPackage
            ? Text(l10n.appPickerSmsHint, style: Theme.of(context).textTheme.bodySmall)
            : null,
        controlAffinity: ListTileControlAffinity.trailing,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        tileColor: selected ? AppColors.primaryStart.withValues(alpha: isDark ? 0.12 : 0.08) : null,
        activeColor: AppColors.primaryStart,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }
}
