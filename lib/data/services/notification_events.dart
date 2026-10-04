import 'package:flutter/services.dart';

/// Live updates from the native listener: one event each time the archive
/// changes ("posted", "updated" when a photo was attached, "recalled").
///
/// The archive used to be read once per screen and never again, so anything
/// that arrived while the app was open stayed invisible until a cold start.
class NotificationEvents {
  NotificationEvents._();

  static const _channel = EventChannel('com.example.notification_keeper/events');

  static Stream<String> get stream =>
      _channel.receiveBroadcastStream().map((event) => event.toString());
}
