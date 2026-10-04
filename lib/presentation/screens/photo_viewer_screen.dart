import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/models/notification_model.dart';
import '../theme/app_colors.dart';
import '../../l10n/generated/app_localizations.dart';

/// Full-screen view of a photo kept by the photo vault.
///
/// Pinch or double-tap to zoom, share/save through the system sheet, and a
/// caption that says plainly when the sender has deleted the message - the
/// whole point of keeping the copy.
class PhotoViewerScreen extends StatefulWidget {
  final NotificationModel notification;

  const PhotoViewerScreen({super.key, required this.notification});

  /// Hero tag shared with the thumbnail that opens the viewer.
  static String heroTag(NotificationModel n) => 'photo-${n.id}';

  /// Opens the viewer with a fade, so the Hero flight reads as the photo
  /// lifting out of the sheet rather than a new page sliding in.
  static Future<void> open(BuildContext context, NotificationModel notification) {
    HapticFeedback.selectionClick();
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.black,
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
        pageBuilder: (context, animation, secondaryAnimation) => PhotoViewerScreen(notification: notification),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen>
    with SingleTickerProviderStateMixin {
  final TransformationController _transform = TransformationController();
  late final AnimationController _zoomController;
  Animation<Matrix4>? _zoomAnimation;
  TapDownDetails? _doubleTapDetails;
  bool _chromeVisible = true;

  @override
  void initState() {
    super.initState();
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        final animation = _zoomAnimation;
        if (animation != null) _transform.value = animation.value;
      });
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _toggleZoom() {
    final zoomedIn = _transform.value.getMaxScaleOnAxis() > 1.01;
    final Matrix4 target;
    if (zoomedIn) {
      target = Matrix4.identity();
    } else {
      // Zoom 2.5x towards the point that was tapped.
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      const scale = 2.5;
      target = Matrix4.identity()
        ..translateByDouble(-position.dx * (scale - 1), -position.dy * (scale - 1), 0, 1)
        ..scaleByDouble(scale, scale, 1, 1);
    }
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (reduceMotion) {
      _transform.value = target;
      return;
    }
    _zoomAnimation = Matrix4Tween(begin: _transform.value, end: target)
        .animate(CurvedAnimation(parent: _zoomController, curve: Curves.easeOutCubic));
    _zoomController.forward(from: 0);
  }

  Future<void> _share() async {
    final n = widget.notification;
    final path = n.imagePath;
    if (path == null) return;
    await Share.shareXFiles([XFile(path)], text: n.title);
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.notification;
    final l10n = AppLocalizations.of(context)!;
    final time = DateFormat.yMMMd(Localizations.localeOf(context).toString())
        .add_Hm()
        .format(DateTime.fromMillisecondsSinceEpoch(n.timestamp));

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              onTap: () => setState(() => _chromeVisible = !_chromeVisible),
              onDoubleTapDown: (d) => _doubleTapDetails = d,
              onDoubleTap: _toggleZoom,
              child: InteractiveViewer(
                transformationController: _transform,
                minScale: 1,
                maxScale: 5,
                child: Center(
                  child: Hero(
                    tag: PhotoViewerScreen.heroTag(n),
                    child: Image.file(
                      File(n.imagePath!),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Top bar: close + share.
            _Chrome(
              visible: _chromeVisible,
              alignment: Alignment.topCenter,
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: l10n.closeAction,
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: l10n.sharePhoto,
                      icon: const Icon(Icons.ios_share_rounded, color: Colors.white),
                      onPressed: _share,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom caption: who sent it, when, and whether it was withdrawn.
            _Chrome(
              visible: _chromeVisible,
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (n.isRecalled) ...[
                        Row(
                          children: [
                            const Icon(Icons.undo_rounded, size: 16, color: AppColors.warning),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.photoKeptAfterRecall,
                                style: const TextStyle(
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],
                      Text(
                        n.messagingUser ?? n.title ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(time, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fading gradient bar that carries the viewer's controls and caption.
class _Chrome extends StatelessWidget {
  final bool visible;
  final Alignment alignment;
  final Widget child;

  const _Chrome({required this.visible, required this.alignment, required this.child});

  @override
  Widget build(BuildContext context) {
    final top = alignment == Alignment.topCenter;
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        ignoring: !visible,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: top ? Alignment.topCenter : Alignment.bottomCenter,
                end: top ? Alignment.bottomCenter : Alignment.topCenter,
                colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
