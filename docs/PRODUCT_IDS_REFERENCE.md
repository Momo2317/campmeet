# Product IDs Reference Card

Schnelle Referenz für alle Produkt-IDs die in App Store Connect und Google Play Console eingegeben werden müssen.

---

## 🎯 Subscriptions (Auto-Renewable)

| Product ID | Name | Preis | Dauer |
|------------|------|-------|-------|
| `campmeet.premium.monthly` | Premium Monthly | 3,99 € | 1 Monat |
| `campmeet.premium.annual` | Premium Annual | 29,99 € | 1 Jahr |

**Features für beide:**
- Unbegrenzte Likes
- 5 Super-Likes täglich
- Boosts (monatlich)
- Keine Werbung
- Erweiterte Filter
- Lese-Bestätigungen im Chat
- Reisepass Feature
- Annual hat zusätzlich: Premium-Badge

---

## 🚀 Consumables: Boosts

| Product ID | Name | Preis | Typ |
|------------|------|-------|-----|
| `campmeet.boost.1` | 1 Boost | 0,99 € | Consumable |
| `campmeet.boost.5` | 5 Boosts Pack | 3,99 € | Consumable (20% Ersparnis) |
| `campmeet.boost.10` | 10 Boosts Pack | 6,99 € | Consumable (30% Ersparnis) |

**Was ist ein Boost?**
- Erhöht die Sichtbarkeit des Profils für 30 Minuten
- Nutzer können mehrfach kaufen
- Mehrfache Boosts können kombiniert werden

---

## ❤️ Consumables: Super Likes

| Product ID | Name | Preis | Typ |
|------------|------|-------|-----|
| `campmeet.superlike.5` | 5 Super Likes | 2,99 € | Consumable |
| `campmeet.superlike.20` | 20 Super Likes | 9,99 € | Consumable (20% Ersparnis) |

**Was ist ein Super Like?**
- Zeigt dem anderen Nutzer besonderes Interesse
- Wird oben in der Liste angezeigt
- Nutzer können mehrfach kaufen
- Freie Super Likes: 1 pro Monat (nicht-bezahlt)

---

## 📋 Vollständige Liste für Copy-Paste

### iOS App Store Connect
```
campmeet.premium.monthly
campmeet.premium.annual
campmeet.boost.1
campmeet.boost.5
campmeet.boost.10
campmeet.superlike.5
campmeet.superlike.20
```

### Android Google Play Console
```
campmeet.premium.monthly
campmeet.premium.annual
campmeet.boost.1
campmeet.boost.5
campmeet.boost.10
campmeet.superlike.5
campmeet.superlike.20
```

---

## 🔧 Im Code registriert unter:

**Datei**: `lib/core/services/payment_service.dart`

```dart
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

  // Alle Produkte
  static const List<String> allProductIds = [
    premiumMonthly, premiumAnnual,
    boost1, boost5, boost10,
    superLike5, superLike20,
  ];

  // Nur Subscriptions
  static const List<String> subscriptionIds = [
    premiumMonthly, premiumAnnual,
  ];
}
```

---

## ⚠️ Wichtige Hinweise

1. **Exakte Schreibweise**: Product IDs müssen EXAKT wie oben geschrieben sein (Groß-/Kleinschreibung zählt!)
2. **Keine Umlaute**: Verwende nur ASCII-Zeichen (keine ä, ö, ü, etc.)
3. **Nur Punkte**: Als Trennzeichen nur `.` verwenden
4. **Beide Stores**: Produkt-ID muss in BEIDEN App Store Connect UND Google Play Console gleich sein

---

## 🌍 Preise nach Region (Beispiel)

### Subscription-Tier 1 (3,99€ / 0,99€)

| Region | Monthly | Annual |
|--------|---------|--------|
| Deutschland | 3,99 € | 29,99 € |
| Österreich | 3,99 € | 29,99 € |
| Schweiz | 4,50 CHF | 34,50 CHF |
| USA | 3.99 USD | 29.99 USD |
| UK | 3.49 GBP | 27.99 GBP |

**Hinweis**: App Store und Google Play berechnen Steuern automatisch. Die Preise oben sind Netto-Preise.

---

## ✅ Checklist für Store Setup

### ✔ iOS App Store Connect
- [ ] In-App Purchases Sektion öffnen
- [ ] Alle 7 Produkte erstellen
- [ ] Product IDs exakt wie oben eingeben
- [ ] Preise eintragen
- [ ] Zahlungsgruppe für Subscriptions setzen
- [ ] Lokalisierungen hinzufügen (optional)
- [ ] Vor Review speichern

### ✔ Android Google Play Console
- [ ] In-App Products Sektion öffnen
- [ ] Alle 7 Produkte erstellen
- [ ] Product IDs exakt wie oben eingeben
- [ ] Preise eintragen
- [ ] Subscriptions in Subscription-Gruppe setzen
- [ ] Vor Release speichern

---

## 📞 Support

Falls bei der Eingabe der Product IDs Probleme auftreten:
1. Überprüfe auf Copy-Paste Fehler
2. Stelle sicher, dass keine Leerzeichen am Anfang/Ende sind
3. Überprüfe Groß-/Kleinschreibung
4. Vergleiche mit der Official-Liste oben

Alle 7 Produkte müssen gespeichert sein, bevor du die App reviewen lässt!
