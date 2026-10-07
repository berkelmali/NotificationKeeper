import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../domain/apps/known_apps.dart';

/// What the UI needs to show an app: its real name and icon.
@immutable
class AppIdentity {
  final String packageName;
  final String label;
  final Uint8List? icon;

  /// False when the app is no longer on this phone (uninstalled since its
  /// notifications were archived, or the archive came from a backup).
  final bool installed;

  const AppIdentity({
    required this.packageName,
    required this.label,
    this.icon,
    this.installed = true,
  });

  factory AppIdentity.fromMap(Map<Object?, Object?> map) {
    final packageName = map['packageName'] as String;
    final label = map['label'] as String?;
    return AppIdentity(
      packageName: packageName,
      // Android's label when the app is installed; otherwise the verified
      // known-app table, then a readable guess from the package name.
      label: (label != null && label.trim().isNotEmpty) ? label : KnownApps.labelFor(packageName),
      icon: map['icon'] as Uint8List?,
      installed: map['installed'] == true,
    );
  }
}

/// App detection for the whole UI: resolves package names to real names and
/// icons through Android's PackageManager, once, and shares the result.
///
/// Before this, four widgets each carried their own copy of a helper that
/// guessed the name from the last package segment - Telegram showed up as
/// "Messenger", Instagram as "Android", Gmail as "Gm" - and every avatar was a
/// coloured letter.
///
/// Lookups are cheap to request: [ensure] queues a package, and everything
/// queued within one frame goes to the platform in a single batched call.
/// Until the answer arrives, [labelFor] already returns the best synchronous
/// guess, so first paint is right for every well-known app.
class AppRegistry extends ChangeNotifier {
  static const _channel = MethodChannel('com.example.notification_keeper/notifications');

  /// Rendered icon edge in pixels: crisp for a 48dp avatar on a 3x screen.
  static const int iconSize = 144;

  final Map<String, AppIdentity> _resolved = {};
  final Set<String> _queued = {};
  final Set<String> _inFlight = {};
  Timer? _flushTimer;

  /// Real name if resolved, otherwise the best guess available right now.
  String labelFor(String packageName) =>
      _resolved[packageName]?.label ?? KnownApps.labelFor(packageName);

  /// The app's icon as PNG bytes, once resolved.
  Uint8List? iconFor(String packageName) => _resolved[packageName]?.icon;

  AppIdentity? identityOf(String packageName) => _resolved[packageName];

  bool isResolved(String packageName) => _resolved.containsKey(packageName);

  /// Asks for [packageName] to be resolved. Safe to call from build(): it only
  /// queues work, and listeners are notified later when results arrive.
  void ensure(String packageName) {
    if (packageName.isEmpty ||
        _resolved.containsKey(packageName) ||
        _inFlight.contains(packageName) ||
        !_queued.add(packageName)) {
      return;
    }
    _flushTimer ??= Timer(Duration.zero, _flush);
  }

  void ensureAll(Iterable<String> packageNames) => packageNames.forEach(ensure);

  Future<void> _flush() async {
    _flushTimer = null;
    if (_queued.isEmpty) return;
    final batch = _queued.toList();
    _queued.clear();
    _inFlight.addAll(batch);

    try {
      final result = await _channel.invokeListMethod<Object?>('getAppIdentities', {
        'packages': batch,
        'iconSize': iconSize,
      });
      for (final entry in result ?? const []) {
        if (entry is Map) {
          final identity = AppIdentity.fromMap(entry.cast<Object?, Object?>());
          _resolved[identity.packageName] = identity;
        }
      }
    } catch (e) {
      // Platform unavailable (tests, or a failed call): remember the fallback so
      // we do not retry on every frame, and keep showing the best guess.
      debugPrint('App lookup failed for ${batch.length} packages: $e');
      for (final pkg in batch) {
        _resolved.putIfAbsent(
          pkg,
          () => AppIdentity(packageName: pkg, label: KnownApps.labelFor(pkg), installed: false),
        );
      }
    } finally {
      _inFlight.removeAll(batch);
    }
    notifyListeners();
    // Anything requested while this batch was in flight.
    if (_queued.isNotEmpty) _flushTimer ??= Timer(Duration.zero, _flush);
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    super.dispose();
  }
}

/// App names and icons from any widget.
///
/// Uses the [AppRegistry] above the widget when there is one - and rebuilds
/// when its lookups land - and falls back to the verified known-app table when
/// there is not, so widgets keep working in isolation (tests, previews).
extension AppRegistryLookup on BuildContext {
  AppRegistry? get _registry => Provider.of<AppRegistry?>(this);

  String appLabel(String packageName) {
    final registry = _registry;
    if (registry == null) return KnownApps.labelFor(packageName);
    registry.ensure(packageName);
    return registry.labelFor(packageName);
  }

  Uint8List? appIcon(String packageName) {
    final registry = _registry;
    if (registry == null) return null;
    registry.ensure(packageName);
    return registry.iconFor(packageName);
  }
}
