import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Model für eine simulated Push-Nachricht
class PushMessage {
  final String title;
  final String body;
  final String target; // 'Alle Nutzer', 'Premium', etc.
  final DateTime timestamp;

  PushMessage({
    required this.title,
    required this.body,
    required this.target,
    required this.timestamp,
  });
}

/// Provider für den Notification-Simulator (Modern Riverpod 3.0 Syntax)
final notificationSimulatorProvider =
    NotifierProvider<NotificationSimulator, PushMessage?>(() {
  return NotificationSimulator();
});

class NotificationSimulator extends Notifier<PushMessage?> {
  @override
  PushMessage? build() {
    return null; // Keine Nachricht am Anfang
  }

  /// Sendet eine Nachricht an alle/bestimmte Nutzer (Simuliert)
  void notifyUsers(String body, String target) {
    state = PushMessage(
      title: '📣 CampMeet Update',
      body: body,
      target: target,
      timestamp: DateTime.now(),
    );
  }

  /// Setzt die Nachricht zurück (z.B. nach dem Anzeigen)
  void clear() {
    state = null;
  }
}
