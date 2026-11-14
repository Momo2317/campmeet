# Payment Implementation Guide
## Apple App Store & Google Play Store Integration

---

## 📋 Überblick

Campus Match hat eine neue Payment-Infrastruktur erhalten, die Apple App Store und Google Play Store direkt nutzt - **ohne RevenueCat**.

### Was wurde geändert:
- ✅ `RevenueCatService` → `PaymentService` (neue Datei)
- ✅ `in_app_purchase` Package statt `purchases_flutter`
- ✅ Vereinfachte Preisstruktur: 2 Subscription-Tiers (Monatlich 3,99€ + Jährlich 29,99€)
- ✅ Neue Premium Page UI mit besserer Darstellung
- ✅ Automatisches Entitlement-Management

---

## 🚀 Schnellstart Checklist

### 1. Dependencies installieren
```bash
flutter pub get
```

### 2. iOS konfigurieren (PAYMENT_SETUP_iOS.md)
- [ ] In App Store Connect 7 Produkte erstellen
- [ ] Product IDs exakt eintragen
- [ ] Preise: Monthly 3,99€, Annual 29,99€
- [ ] Xcode: In-App Purchase Capability aktivieren
- [ ] Mit TestFlight testen

### 3. Android konfigurieren (PAYMENT_SETUP_Android.md)
- [ ] In Google Play Console 7 Produkte erstellen
- [ ] Product IDs exakt eintragen
- [ ] Preise: Monthly 3,99€, Annual 29,99€
- [ ] Gradle build.gradle aktualisieren
- [ ] Permissions in AndroidManifest.xml prüfen
- [ ] Mit Internal Testing testen

### 4. App testen
```bash
flutter run --release
```

---

## 📁 Neue Dateien

### `lib/core/services/payment_service.dart`
Die zentrale Payment-Service Klasse mit:
- `initialize()` - App-Start beim Laden
- `purchaseSubscription(productId)` - Subscription kaufen
- `purchaseConsumable(productId)` - Boosts/Super Likes kaufen
- `restorePurchases()` - Käufe wiederherstellen
- `hasPremium()` - Premium Status prüfen
- `setPremium(value)` - Premium Status speichern
- Stream Listener für Purchase Updates

### `docs/PAYMENT_SETUP_iOS.md`
Komplette Schritt-für-Schritt Anleitung für iOS.

### `docs/PAYMENT_SETUP_Android.md`
Komplette Schritt-für-Schritt Anleitung für Android.

---

## 🔧 Code Änderungen Übersicht

### main.dart
```dart
// Vorher:
await RevenueCatService().initialize();

// Nachher:
try {
  await PaymentService().initialize();
} catch (e) {
  debugPrint('⚠️ PaymentService konnte nicht initialisiert werden: $e');
}
```

### premium_page.dart
```dart
// Vorher:
await RevenueCatService().restorePurchases();

// Nachher:
await PaymentService().restorePurchases();
```

### premium_carousel.dart
**Komplett überarbeitet:**
- Nur 2 Subscription-Pläne statt 9
- Neue Preise: 3,99€ (Monthly), 29,99€ (Annual)
- Einfachere UI, bessere Nutzer-Experience
- Direkte Integration mit PaymentService

---

## 📦 Produkt-IDs (müssen im Store konfiguriert werden)

### Subscriptions
```
campmeet.premium.monthly  → 3,99 EUR (1 Monat)
campmeet.premium.annual   → 29,99 EUR (1 Jahr)
```

### Consumables (Boosts)
```
campmeet.boost.1          → 0,99 EUR
campmeet.boost.5          → 3,99 EUR (20% sparen)
campmeet.boost.10         → 6,99 EUR (30% sparen)
```

### Consumables (Super Likes)
```
campmeet.superlike.5      → 2,99 EUR
campmeet.superlike.20     → 9,99 EUR (20% sparen)
```

---

## 🔐 Entitlement Management

Premium-Status wird in **SharedPreferences** lokal gespeichert:

```dart
// Premium Status speichern (nach erfolgreichem Kauf)
await PaymentService().setPremium(true);

// Premium Status prüfen
final hasPremium = await PaymentService().hasPremium();

// Bei App-Start automatisch wiederhergestellt:
// PaymentService.initialize() → _updateEntitlements() → setPremium()
```

---

## ⚙️ Wichtige Implementierungs-Details

### iOS (StoreKit 2)
- **API Level**: iOS 15.1+ erforderlich
- **Capability**: In-App Purchase in Xcode aktivieren
- **Transaktionen**: Apple verwaltet automatisch
- **Status**: App Store automatisch mit Abonnements verwaltet
- **Testing**: TestFlight mit Test-Accounts oder Simulator

### Android (Google Play Billing v7+)
- **API Level**: minSdkVersion 21 (Android 5.0+)
- **Library**: `com.android.billingclient:billing:7.0.0`
- **Transaktionen**: Google Play verwaltet automatisch
- **Status**: Play Console zeigt aktive Subscriptions
- **Testing**: Internal Testing oder Play Billing Library Sandbox

### Shared Sync Status
⚠️ **Wichtig**: Der Premium-Status wird **pro Gerät** verwaltet (nicht zwischen iOS & Android synchronisiert). Das ist gewolltes Verhalten nach deinen Anforderungen.

Falls später Cross-Device-Sync gewünscht: Könnte ein Backend-System implementiert werden, das Kaufentitlements verwaltet.

---

## 🧪 Testing Strategie

### Development (Lokal)
```bash
flutter run --debug
```
- Mock-Mode für in_app_purchase
- Produkte funktionieren im Simulator (begrenzt)

### Release Testing (iOS)
1. Build: `flutter build ios --release`
2. Upload zu TestFlight
3. Mit Test-Account kaufen
4. Verifiziere: Premium aktiviert sich ✅

### Release Testing (Android)
1. Build: `flutter build apk --release`
2. Upload zu Google Play (Internal Testing)
3. Mit Test-Account kaufen
4. Verifiziere: Premium aktiviert sich ✅

---

## 📊 Preisgestaltung

| Plan | Monat | Beschreibung |
|------|-------|-------------|
| **Premium Monthly** | 3,99€ | Flexibel, monatlich kündbar |
| **Premium Annual** | 29,99€ | Sparen Sie 58%! |

**Premium Features:**
- ✨ Unbegrenzte Likes
- ❤️ 5 Super-Likes täglich
- 🚀 1-5 Boosts pro Monat
- 📵 Keine Werbung
- 🔍 Erweiterte Filter
- 💬 Lese-Bestätigungen im Chat
- 🌍 Reisepass (Ort ändern)
- 👑 Premium-Badge (nur Annual)

---

## 🐛 Troubleshooting

### "Product not found" Fehler
**Ursache**: Produkt nicht in App Store/Play Console konfiguriert
**Lösung**: Überprüfe Produktnames und IDs im Store (genaue Übereinstimmung erforderlich)

### Käufe funktionieren nicht
**Ursache**: PaymentService nicht initialisiert
**Lösung**: Überprüfe main.dart initialization - sollte vor runApp() erfolgen

### Premium-Status wird nicht gespeichert
**Ursache**: SharedPreferences Problem
**Lösung**: Überprüfe _updateEntitlements() Logik in payment_service.dart

### "Billing not available" Android
**Ursache**: Google Play Services nicht aktuell
**Lösung**: Erzwinge Update von Google Play Services auf Gerät

---

## 📝 Nächste Schritte

1. **iOS Setup**: Folge `PAYMENT_SETUP_iOS.md`
2. **Android Setup**: Folge `PAYMENT_SETUP_Android.md`
3. **Flutter Dependencies**: `flutter pub get`
4. **Test lokal**: `flutter run --debug`
5. **TestFlight/Internal Testing**: Lade Release APK/IPA hoch
6. **Production Release**: Wenn alles getestet, zur Review einreichen

---

## 📚 Referenzen

- [in_app_purchase Package](https://pub.dev/packages/in_app_purchase)
- [Apple StoreKit 2](https://developer.apple.com/storekit/)
- [Google Play Billing](https://developer.android.com/google-play/billing)

---

## 💬 Support & Fragen

Falls Probleme auftreten:
1. Überprüfe die Logs: `flutter logs`
2. Überprüfe Payment Service Initialisierung
3. Überprüfe Product IDs im Store vs. Code
4. TestFlight/Internal Testing verwenden (nicht nur Simulator/Emulator)

---

**Status**: ✅ Bereit zur Implementierung in App Store & Google Play
