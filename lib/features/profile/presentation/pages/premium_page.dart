import 'package:camp_meet/core/theme/app_theme.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:camp_meet/core/services/payment_service.dart';
import 'package:camp_meet/features/profile/presentation/widgets/premium_carousel.dart';

class PremiumPage extends StatelessWidget {
  const PremiumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.darkTheme,
      child: Builder(builder: (context) => _buildDark(context)),
    );
  }

  Widget _buildDark(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
        actions: [
          // Käufe wiederherstellen
          TextButton(
            onPressed: () async {
              final restored = await PaymentService().restorePurchases();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  restored
                      ? 'Premium wiederhergestellt'
                      : 'Kein aktives Abonnement gefunden',
                  style: TextStyle(),
                ),
                backgroundColor: restored
                    ? const Color(0xFF9B30FF)
                    : const Color(0xFFFF4B6E),
              ));
            },
            child: Text(
              'Wiederherstellen',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF231D45), Color(0xFF0F0B24)],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),

              // Hero Header
              Text(
                'CampMeet Premium',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Finde schneller dein Perfect Match',
                style: TextStyle(fontSize: 15, color: Colors.white60),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Premium Carousel mit allen 3 Plänen + RC-Kaufflow
              const PremiumCarousel(),

              const SizedBox(height: 30),

              // Trust badges
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _TrustBadge(
                        icon: CupertinoIcons.lock_fill, label: 'Sicher'),
                    _TrustBadge(
                        icon: CupertinoIcons.clear_circled_solid,
                        label: 'Jederzeit kündbar'),
                    _TrustBadge(
                        icon: CupertinoIcons.checkmark_seal_fill,
                        label: 'Geprüft'),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Legal disclaimer
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Text(
                  'Abonnements werden automatisch verlängert, sofern sie nicht mindestens 24 Stunden vor Ablauf des aktuellen Zeitraums über die App-Store-Einstellungen gekündigt werden. Die Zahlung wird bei Bestätigung des Kaufs über deinen App-Store-Account abgebucht.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white24, fontSize: 10, height: 1.5),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TrustBadge({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white12),
          ),
          child: Icon(icon, color: Colors.white54, size: 18),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(color: Colors.white38, fontSize: 11),
        ),
      ],
    );
  }
}
