import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camp_meet/core/theme/app_theme.dart';
import 'package:camp_meet/features/auth/presentation/pages/auth_page.dart';
import 'package:camp_meet/features/home/app_home.dart';
import 'package:camp_meet/features/profile/data/user_profile_repository.dart';
import 'package:camp_meet/core/services/payment_service.dart';
import 'package:camp_meet/core/services/ad_service.dart';
import 'package:camp_meet/core/services/maintenance_service.dart';
import 'package:camp_meet/features/admin/presentation/pages/maintenance_screen.dart';
import 'package:camp_meet/core/services/notification_simulator.dart';
import 'package:camp_meet/core/firebase/firebase_config.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Firebase initialisieren
  try {
    await FirebaseConfig.initialize();
  } catch (e) {
    debugPrint('⚠️ Firebase konnte nicht initialisiert werden: $e');
  }

  // 💰 Apple & Google Store Payment Service initialisieren
  try {
    await PaymentService().initialize();
  } catch (e) {
    debugPrint('⚠️ PaymentService konnte nicht initialisiert werden: $e');
  }

  // 📢 AdMob initialisieren
  await AdService().initialize();

  final container = ProviderContainer();
  // Bezahlte Boosts / Super Likes dem Profil gutschreiben
  PaymentService().onConsumablePurchased = (productId) {
    final credit = ProductIds.consumableCredits[productId];
    if (credit == null) return;
    container.read(userProfileProvider.notifier).addCredits(
          superLikes: credit.superLikes,
          boosts: credit.boosts,
        );
  };

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const CampMeetApp(),
    ),
  );
}

class CampMeetApp extends ConsumerWidget {
  const CampMeetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMaintenance = ref.watch(maintenanceProvider);

    // 🔔 Notification Listener
    ref.listen<PushMessage?>(notificationSimulatorProvider, (previous, next) {
      if (next != null) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.transparent,
            elevation: 0,
            duration: const Duration(seconds: 5),
            content: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFFF2D9B),
                    Color(0xFF9B30FF),
                    Color(0xFF5B2BF0)
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF9B30FF).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          next.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          next.body,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Jetzt',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        // Nachricht als "gelesen/erhalten" markieren
        ref.read(notificationSimulatorProvider.notifier).clear();
      }
    });

    final isLoggedIn = ref.watch(authSessionProvider);

    Widget homeWidget;
    if (isMaintenance) {
      homeWidget = const MaintenanceScreen();
    } else if (isLoggedIn) {
      homeWidget = const AppHome();
    } else {
      homeWidget = const AuthPage();
    }

    return MaterialApp(
      title: 'CampMeet',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: scaffoldMessengerKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ref.watch(themeModeProvider),
      home: homeWidget,
    );
  }
}
