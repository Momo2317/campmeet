import 'package:flutter/material.dart';
import 'package:camp_meet/core/services/payment_service.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Werbekarten-System (wie Tinder)
//
// Ads werden als Profil-Karten im Swipe-Deck angezeigt.
// ❤️ / Swipe rechts → öffnet die Werbung (URL in-app)
// ❌ / Swipe links  → überspringt die Werbung
// Premium-User sehen keine Werbung.
// ─────────────────────────────────────────────────────────────────────────────

/// Definiert eine einzelne Werbekarte
class AdCard {
  final String id;
  final String title; // z.B. Firmenname
  final String subtitle; // z.B. "Gesponsert"
  final String description; // z.B. Slogan oder Kurzbeschreibung
  final String imageUrl; // Vollbild-Bild (wie Profilbild)
  final String targetUrl; // URL die bei Swipe rechts geöffnet wird
  final String? ctaText; // z.B. "Jetzt entdecken" / "Mehr erfahren"
  final Color accentColor;

  const AdCard({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.imageUrl,
    required this.targetUrl,
    this.ctaText,
    this.accentColor = Colors.blueAccent,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Ad Service
// ─────────────────────────────────────────────────────────────────────────────

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;

  /// Globale Steuerung für das Werbe-System (Standard: aus)
  static bool isAdsEnabled = false;

  /// Nach wie vielen echten Profilen eine Werbekarte kommt
  static int profilesBetweenAds = 5;

  /// Initialisiert den Ad Service
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    isAdsEnabled = prefs.getBool('ads_enabled') ?? false;
    profilesBetweenAds = prefs.getInt('ads_frequency') ?? 5;
    _isInitialized = true;
    debugPrint(
        '📢 AdService initialisiert (Enabled: $isAdsEnabled) – Werbekarten alle $profilesBetweenAds Profile');
  }

  /// Prüft ob der Nutzer Werbung sehen soll
  Future<bool> shouldShowAds() async {
    if (!_isInitialized || !isAdsEnabled) return false;
    return !(await PaymentService().hasPremium());
  }

  /// Gibt die Mock-Werbekarten zurück
  /// ⚠️ TODO: Später durch echte Ad-API ersetzen (z.B. AdMob Native Ads)
  List<AdCard> getAdCards() {
    return _mockAdCards;
  }

  /// Callback wenn User auf eine Ad-Karte swipe-right macht
  Future<void> onAdClicked(AdCard ad) async {
    debugPrint('📢 Ad geklickt: ${ad.title} → ${ad.targetUrl}');

    final url = Uri.parse(ad.targetUrl);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('⚠️ Konnte Werbung nicht öffnen: ${ad.targetUrl}');
    }

    // ⚠️ TODO: Analytics-Event senden
    // ⚠️ TODO: Einnahmen-Tracking
  }

  /// Callback wenn User eine Ad-Karte dismisst (swipe-left)
  void onAdDismissed(AdCard ad) {
    debugPrint('📢 Ad übersprungen: ${ad.title}');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mock-Werbekarten (später durch echte Ads ersetzen)
// ─────────────────────────────────────────────────────────────────────────────
final List<AdCard> _mockAdCards = [
  AdCard(
    id: 'ad_1',
    title: 'StudySmarter',
    subtitle: 'Gesponsert',
    description:
        'Die #1 Lern-App für Studenten. Karteikarten, Zusammenfassungen & mehr.',
    imageUrl:
        'https://images.unsplash.com/photo-1522202176988-66273c2fd55f?w=800',
    targetUrl: 'https://www.studysmarter.de',
    ctaText: 'Jetzt gratis testen',
    accentColor: Colors.tealAccent,
  ),
  AdCard(
    id: 'ad_2',
    title: 'CLARK',
    subtitle: 'Gesponsert',
    description:
        'Deine Versicherungen in einer App. Spezial-Tarife für Studenten.',
    imageUrl: 'https://images.unsplash.com/photo-1554224155-6726b3ff858f?w=800',
    targetUrl: 'https://www.clark.de',
    ctaText: 'Mehr erfahren',
    accentColor: Colors.orangeAccent,
  ),
  AdCard(
    id: 'ad_3',
    title: 'Spotify Premium',
    subtitle: 'Gesponsert',
    description:
        'Studenten-Rabatt: Premium für nur 4,99 €/Monat. Musik ohne Werbung.',
    imageUrl:
        'https://images.unsplash.com/photo-1611339555312-e607c8352fd7?w=800',
    targetUrl: 'https://www.spotify.com/de/student/',
    ctaText: 'Jetzt 1 Monat gratis',
    accentColor: Colors.greenAccent,
  ),
  AdCard(
    id: 'ad_4',
    title: 'Lieferando',
    subtitle: 'Gesponsert',
    description:
        'Hungrig nach der Vorlesung? 5 € Rabatt auf deine erste Bestellung.',
    imageUrl:
        'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800',
    targetUrl: 'https://www.lieferando.de',
    ctaText: 'Code: CAMPUS5',
    accentColor: Colors.deepOrangeAccent,
  ),
];
