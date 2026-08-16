import 'package:flutter/material.dart';
import '../../data/repositories/notification_repository.dart';
import '../theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

class PermissionScreen extends StatefulWidget {
  // BUG FIX: was VoidCallback - the button had no way to know whether the
  // recheck actually found the permission enabled, so tapping "I have
  // enabled it" before Android had registered the change (or before the
  // user had actually toggled it) did nothing visible at all.
  final Future<bool> Function() onPermissionGranted;

  const PermissionScreen({super.key, required this.onPermissionGranted});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  final NotificationRepository _repo = NotificationRepository();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  // BUG FIX: tracks whether a recheck is in flight, so the button can show
  // a "Checking..." state and, if it still comes back false, tell the user
  // clearly instead of appearing to do nothing.
  bool _isCheckingPermission = false;

  // New feature: pages are now built from AppLocalizations at runtime
  // instead of a static const list, since translated strings aren't
  // compile-time constants.
  List<_OnboardingPage> _pages(AppLocalizations l10n) => [
    _OnboardingPage(
      icon: Icons.notifications_rounded,
      gradient: AppColors.primaryGradient,
      title: l10n.onboardTitle1,
      description: l10n.onboardDesc1,
    ),
    _OnboardingPage(
      icon: Icons.history_rounded,
      gradient: AppColors.accentGradient,
      title: l10n.onboardTitle2,
      description: l10n.onboardDesc2,
    ),
    _OnboardingPage(
      icon: Icons.security_rounded,
      gradient: const LinearGradient(
        colors: [AppColors.warning, Color(0xFFFF9F43)],
      ),
      title: l10n.onboardTitle3,
      description: l10n.onboardDesc3,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// BUG FIX: previously this button called widget.onPermissionGranted
  /// directly with no way to know if the recheck actually found the
  /// permission enabled - if the user tapped it before Android had
  /// registered the change (or before actually toggling it), absolutely
  /// nothing visible happened, which read as "the app doesn't open".
  Future<void> _handleCheckPermission(AppLocalizations l10n) async {
    setState(() => _isCheckingPermission = true);

    final enabled = await widget.onPermissionGranted();

    if (!mounted) return;
    setState(() => _isCheckingPermission = false);

    if (!enabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.permissionStillNotEnabled)),
      );
    }
    // If enabled is true, MainScreen's own build() will already switch away
    // from this screen on the next frame (its state was updated inside
    // widget.onPermissionGranted) - nothing further to do here.
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final pages = _pages(l10n);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? AppColors.darkGradient : null,
          color: isDark ? null : AppColors.backgroundLight,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ─── Pages ───
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: pages.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    return _buildPage(pages[index]);
                  },
                ),
              ),

              // ─── Page Indicator ───
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pages.length, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: _currentPage == index
                          ? AppColors.primaryStart
                          : (isDark
                              ? AppColors.cardBorder
                              : AppColors.cardBorderLight),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // ─── Actions ───
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    if (_currentPage == pages.length - 1) ...[
                      // Last page: show permission button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primaryStart
                                    .withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await _repo.openNotificationSettings();
                            },
                            icon: const Icon(Icons.settings_rounded),
                            label: Text(l10n.openSettingsAction),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _isCheckingPermission ? null : () => _handleCheckPermission(l10n),
                        child: Text(
                          _isCheckingPermission ? l10n.checkingPermission : l10n.iHaveEnabledIt,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondary
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ] else ...[
                      // Other pages: Next
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: Text(l10n.nextAction),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          _pageController.animateToPage(
                            pages.length - 1,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text(
                          l10n.skipAction,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textTertiary
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon container
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: page.gradient,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: (page.gradient as LinearGradient)
                        .colors
                        .first
                        .withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                page.icon,
                size: 52,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.textSecondary
                      : AppColors.textSecondaryLight,
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final Gradient gradient;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.icon,
    required this.gradient,
    required this.title,
    required this.description,
  });
}
