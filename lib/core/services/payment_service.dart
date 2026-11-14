import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Produkt IDs (müssen in App Store Connect & Google Play Console konfiguriert werden)
// ─────────────────────────────────────────────────────────────────────────────
class ProductIds {
  // Subscriptions
  static const String premiumMonthly = 'campmeet.premium.monthly';
  static const String premiumAnnual = 'campmeet.premium.annual';

  // Consumables (Boosts)
  static const String boost1 = 'campmeet.boost.1';
  static const String boost5 = 'campmeet.boost.5';
  static const String boost10 = 'campmeet.boost.10';

  // Consumables (Super Likes)
  static const String superLike5 = 'campmeet.superlike.5';
  static const String superLike20 = 'campmeet.superlike.20';

  // Alle Produkt IDs
  static const List<String> allProductIds = [
    premiumMonthly,
    premiumAnnual,
    boost1,
    boost5,
    boost10,
    superLike5,
    superLike20,
  ];

  /// Gutschrift pro Consumable: (Super Likes, Boosts)
  static const Map<String, ({int superLikes, int boosts})> consumableCredits = {
    boost1: (superLikes: 0, boosts: 1),
    boost5: (superLikes: 0, boosts: 5),
    boost10: (superLikes: 0, boosts: 10),
    superLike5: (superLikes: 5, boosts: 0),
    superLike20: (superLikes: 20, boosts: 0),
  };

  // Subscription IDs
  static const List<String> subscriptionIds = [
    premiumMonthly,
    premiumAnnual,
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// Kauf-Ergebnis
// ─────────────────────────────────────────────────────────────────────────────
class PurchaseResult {
  final bool success;
  final bool cancelled;
  final bool hasPremium;
  final String? error;

  const PurchaseResult._({
    required this.success,
    required this.cancelled,
    required this.hasPremium,
    this.error,
  });

  factory PurchaseResult.success({bool hasPremium = false}) =>
      PurchaseResult._(success: true, cancelled: false, hasPremium: hasPremium);

  factory PurchaseResult.cancelled() =>
      PurchaseResult._(success: false, cancelled: true, hasPremium: false);

  factory PurchaseResult.error(String message) => PurchaseResult._(
      success: false, cancelled: false, hasPremium: false, error: message);
}

// ─────────────────────────────────────────────────────────────────────────────
// Payment Service
//
// Integration für Apple App Store (StoreKit 2) und Google Play Store (Google Play Billing)
//
// Konfiguration erforderlich:
// 1. iOS: App Store Connect - In-App Purchases konfigurieren
// 2. Android: Google Play Console - In-App Produkte erstellen
// ─────────────────────────────────────────────────────────────────────────────

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();

  factory PaymentService() => _instance;

  PaymentService._internal();

  late InAppPurchase _iap;
  bool _isInitialized = false;
  late SharedPreferences _prefs;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  // Cached products
  Map<String, ProductDetails> _products = {};

  /// Wird aufgerufen, sobald ein Consumable (Boost / Super Like) bezahlt wurde.
  void Function(String productId)? onConsumablePurchased;

  /// Initialisiert den Payment Service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _prefs = await SharedPreferences.getInstance();
      _iap = InAppPurchase.instance;

      // Käufe, Wiederherstellungen und ausstehende Käufe kommen über den Stream
      _purchaseSubscription ??=
          _iap.purchaseStream.listen(_handlePurchaseUpdates);

      // Prüfe ob in-app purchases verfügbar sind
      final available = await _iap.isAvailable();
      if (!available) {
        throw Exception('In-App Purchases nicht verfügbar auf diesem Gerät');
      }

      // Lade Produkte
      await _loadProducts();

      _isInitialized = true;
      debugPrint('✅ PaymentService erfolgreich initialisiert');
    } catch (e) {
      debugPrint('❌ PaymentService Initialisierungsfehler: $e');
      rethrow;
    }
  }

  /// Lädt Produktdetails vom Store
  Future<void> _loadProducts() async {
    try {
      final response =
          await _iap.queryProductDetails(ProductIds.allProductIds.toSet());

      if (response.notFoundIDs.isNotEmpty) {
        debugPrint(
            '⚠️ Folgende Produkte nicht konfiguriert: ${response.notFoundIDs}');
      }

      for (var product in response.productDetails) {
        _products[product.id] = product;
        debugPrint('✅ Produkt geladen: ${product.id} - ${product.title}');
      }
    } catch (e) {
      debugPrint('❌ Fehler beim Laden der Produkte: $e');
      rethrow;
    }
  }

  /// Gibt den formatierten Preis eines Produkts zurück
  String getPriceString(String productId, {String fallback = '–'}) {
    final product = _products[productId];
    if (product == null) return fallback;
    return product.price;
  }

  /// Gibt Produktdetails zurück
  ProductDetails? getProductDetails(String productId) {
    return _products[productId];
  }

  /// Kauft ein Subscription-Produkt
  Future<PurchaseResult> purchaseSubscription(String productId) async {
    if (!_isInitialized) {
      return PurchaseResult.error('PaymentService nicht initialisiert');
    }

    final product = _products[productId];
    if (product == null) {
      return PurchaseResult.error('Produkt "$productId" nicht gefunden');
    }

    try {
      await _iap.buyNonConsumable(
          purchaseParam: PurchaseParam(productDetails: product));
      return PurchaseResult.success();
    } catch (e) {
      if (e.toString().contains('PurchaseException')) {
        return PurchaseResult.cancelled();
      }
      return PurchaseResult.error('Kauf fehlgeschlagen: $e');
    }
  }

  /// Kauft ein Consumable-Produkt (Boosts, Super Likes)
  Future<PurchaseResult> purchaseConsumable(String productId) async {
    if (!_isInitialized) {
      return PurchaseResult.error('PaymentService nicht initialisiert');
    }

    final product = _products[productId];
    if (product == null) {
      return PurchaseResult.error('Produkt "$productId" nicht gefunden');
    }

    try {
      await _iap.buyConsumable(
          purchaseParam: PurchaseParam(productDetails: product));
      return PurchaseResult.success();
    } catch (e) {
      if (e.toString().contains('PurchaseException')) {
        return PurchaseResult.cancelled();
      }
      return PurchaseResult.error('Kauf fehlgeschlagen: $e');
    }
  }

  /// Prüft ob der Benutzer Premium hat
  Future<bool> hasPremium() async {
    try {
      final hasPremium = _prefs.getBool('_hasPremium') ?? false;
      return hasPremium;
    } catch (e) {
      debugPrint('❌ Fehler beim Prüfen von Premium-Status: $e');
      return false;
    }
  }

  /// Setzt Premium-Status
  Future<void> setPremium(bool value) async {
    await _prefs.setBool('_hasPremium', value);
    debugPrint('Premium Status aktualisiert: $value');
  }

  /// Stellt verlorene Käufe wieder her (Ergebnis kommt über den Purchase-Stream)
  Future<bool> restorePurchases() async {
    if (!_isInitialized) {
      return false;
    }

    try {
      await _iap.restorePurchases();
      debugPrint('✅ Wiederherstellung angestoßen');
      return true;
    } catch (e) {
      debugPrint('❌ Fehler beim Wiederherstellen: $e');
      return false;
    }
  }

  /// Verarbeitet Käufe aus dem Purchase-Stream (Kauf, Wiederherstellung, ausstehend)
  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (ProductIds.subscriptionIds.contains(purchase.productID)) {
            await setPremium(true);
            debugPrint(
                '✅ Aktives Subscription gefunden: ${purchase.productID}');
          } else if (purchase.status == PurchaseStatus.purchased &&
              ProductIds.consumableCredits.containsKey(purchase.productID)) {
            // Consumables werden nicht wiederhergestellt, nur bei Neukauf gutschreiben
            onConsumablePurchased?.call(purchase.productID);
          }
          break;
        case PurchaseStatus.error:
          debugPrint('❌ Kauffehler: ${purchase.error}');
          break;
        case PurchaseStatus.pending:
        case PurchaseStatus.canceled:
          break;
      }

      // Kauf abschließen, sonst erstattet der Store ihn nach einiger Zeit zurück
      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
  }

  /// Stream für Purchase-Updates (für UI-Reaktivität)
  Stream<List<PurchaseDetails>> get purchaseUpdates => _iap.purchaseStream;

  /// Alle verfügbaren Produkte
  Map<String, ProductDetails> get products => _products;

  /// Prüfe ob Service initialisiert ist
  bool get isInitialized => _isInitialized;
}
