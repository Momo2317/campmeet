// ⚠️ FIREBASE PUSH NOTIFICATIONS – DEAKTIVIERT
// Wird wieder aktiviert, sobald Firebase im Projekt eingerichtet wurde
// (flutterfire configure + pubspec.yaml Pakete hinzufügen)
//
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/foundation.dart';
//
// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   debugPrint("Handling a background message: ${message.messageId}");
// }
//
// class PushNotificationService {
//   final FirebaseMessaging _fcm = FirebaseMessaging.instance;
//
//   Future<void> initialize() async {
//     NotificationSettings settings = await _fcm.requestPermission(
//       alert: true, badge: true, sound: true,
//     );
//     debugPrint('User granted permission: ${settings.authorizationStatus}');
//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       try {
//         String? token = await _fcm.getToken();
//         debugPrint("FCM Device Token: $token");
//       } catch (e) {
//         debugPrint("Error fetching FCM token: $e");
//       }
//       FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
//       FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//         debugPrint('Got a message whilst in the foreground!');
//       });
//     }
//   }
// }
