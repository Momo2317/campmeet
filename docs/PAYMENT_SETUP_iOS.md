# iOS Payment Setup - App Store Connect

## Schritt 1: App Store Connect Vorbereitung

### 1.1 Gehe zu App Store Connect
1. Öffne https://appstoreconnect.apple.com
2. Melde dich mit deinem Apple Developer Account an
3. Gehe zu "Apps" → wähle deine "CampMeet" App

### 1.2 Zahlungsmethoden und Bankkonto
- Gehe zu "Agreements, Tax, and Banking"
- Stelle sicher, dass ein gültiges Bankkonto hinterlegt ist (für Auszahlungen)
- Akzeptiere die neuesten Vereinbarungen für In-App Purchases

---

## Schritt 2: In-App Produkte erstellen

### 2.1 Subscriptions (Automatisch erneuert)

#### Premium Monthly (3.99€/Monat)
1. Gehe zu "In-App Purchases" → "+"
2. Wähle **"Auto-Renewable Subscription"**
3. Referential Name: `Premium Monthly`
4. Product ID: `campmeet.premium.monthly` (⚠️ WICHTIG: Exakt so!)
5. Zahlungsgruppe: Erstelle eine neue "Premium" Gruppe oder wähle bestehende
6. Lokalisierung (English):
   - Name: `Premium Monthly`
   - Description: `Unlimited likes, no ads, and exclusive features for 1 month`
7. Pricing:
   - Tier 1 (3,99 € / 3.99 USD pro Monat)
   - Verlängerungszeitraum: 1 Monat
8. Klicke "Create"

#### Premium Annual (29.99€/Jahr)
1. Wiederhole obige Schritte für Annual:
2. Product ID: `campmeet.premium.annual`
3. Referential Name: `Premium Annual`
4. Pricing: Tier 1 (29,99 € / 29.99 USD pro Jahr)
5. Verlängerungszeitraum: 1 Jahr
6. **Wichtig**: Setze die gleiche Zahlungsgruppe wie bei Monthly

---

## Schritt 3: Consumable Products (Boosts & Super Likes)

### 3.1 Boosts erstellen

#### Boost 1x
1. Typ: **Non-Consumable** (einmalig) oder **Consumable** (mehrfach)
   - Wir empfehlen **Consumable** damit Nutzer mehrfach kaufen können
2. Product ID: `campmeet.boost.1`
3. Name: `1 Boost`
4. Description: `Boost your profile visibility for 30 minutes`
5. Pricing: Tier 1 (0,99 € / 0.99 USD)

#### Boost 5x Pack
1. Product ID: `campmeet.boost.5`
2. Name: `5 Boosts`
3. Description: `Save 20%: Get 5 boosts for 3,99€`
4. Pricing: Tier 1 (3,99 € / 3.99 USD)

#### Boost 10x Pack
1. Product ID: `campmeet.boost.10`
2. Name: `10 Boosts`
3. Description: `Save 30%: Get 10 boosts for 6,99€`
4. Pricing: Tier 1 (6,99 € / 6.99 USD)

### 3.2 Super Likes erstellen

#### Super Like 5x
1. Product ID: `campmeet.superlike.5`
2. Name: `5 Super Likes`
3. Description: `Let someone know you're really interested`
4. Pricing: Tier 1 (2,99 € / 2.99 USD)

#### Super Like 20x
1. Product ID: `campmeet.superlike.20`
2. Name: `20 Super Likes`
3. Description: `Save 20%: Get 20 Super Likes for 9,99€`
4. Pricing: Tier 1 (9,99 € / 9.99 USD)

---

## Schritt 4: Xcode Konfiguration

### 4.1 Signing & Capabilities
1. Öffne das Projekt in Xcode: `ios/Runner.xcworkspace`
2. Wähle "Runner" Target
3. Gehe zu "Signing & Capabilities"
4. Klicke "+ Capability" → Suche "In-App Purchase"
5. Füge hinzu: `In-App Purchase`

### 4.2 Bundle ID überprüfen
- Stelle sicher dass Bundle ID mit deinem App Store Connect Eintrag übereinstimmt
- Standard: `com.example.campMeet` → ändern zu: `com.yourcompany.campmeet`

---

## Schritt 5: Testen mit TestFlight/Sandbox

### 5.1 Test-Accounts erstellen
1. In App Store Connect → "Users and Access" → "Sandbox"
2. Erstelle Test-Accounts für verschiedene Länder (z.B. USA, Deutschland)
3. Wichtig: Verwende **keine echten Apple IDs**

### 5.2 iOS App auf physischem Gerät deployen
```bash
flutter run --release
```

### 5.3 Mit Test-Account im TestFlight testen
1. Baue Release Build: `flutter build ios --release`
2. Upload zu TestFlight
3. Lade mit Test-Account herunter
4. Teste In-App Purchase

---

## Schritt 6: StoreKit Testing (Simulator/Lokal)

### 6.1 StoreKit Configuration File
1. Xcode: File → New → File → "StoreKit Configuration"
2. Speichern als: `store_config.storekit`
3. Definiere deine Test-Produkte:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<StoreKit>
    <App bundleID="com.yourcompany.campmeet" name="CampMeet">
        <SubscriptionGroup id="com.yourcompany.campmeet.subscriptions">
            <Subscription productID="campmeet.premium.monthly" name="Premium Monthly">
                <Price locale="en_US" tier="1"/>
                <Price locale="de_DE" tier="1"/>
            </Subscription>
            <Subscription productID="campmeet.premium.annual" name="Premium Annual">
                <Price locale="en_US" tier="1"/>
                <Price locale="de_DE" tier="1"/>
            </Subscription>
        </SubscriptionGroup>
        <InAppPurchase productID="campmeet.boost.1" name="1 Boost" type="Consumable">
            <Price locale="en_US" tier="1"/>
            <Price locale="de_DE" tier="1"/>
        </InAppPurchase>
    </App>
</StoreKit>
```

### 6.2 Simulator mit StoreKit testen
1. Xcode: Scheme → Edit Scheme
2. Run → Pre-actions
3. Aktiviere `store_config.storekit`
4. Simulator starten und kaufen testen

---

## Troubleshooting iOS

| Problem | Lösung |
|---------|--------|
| "Product not found" | Prüfe Product ID in Code vs. App Store Connect (Groß-/Kleinschreibung!) |
| "Cannot connect to App Store" | Internet-Verbindung prüfen, Sandbox Account korrekt? |
| Simulator zeigt keine Produkte | StoreKit Config aktivieren oder physisches Gerät testen |
| Kauf lädt endlos | Prüfe Bundle ID, In-App Purchase Capability in Xcode |

---

## Checkliste vor Production

- [ ] Alle 7 Produkte in App Store Connect erstellt
- [ ] Zahlungsgruppen korrekt konfiguriert
- [ ] Xcode In-App Purchase Capability aktiviert
- [ ] TestFlight Build erstellt und mit Test-Account getestet
- [ ] Alle lokalen Preise korrekt eingegeben
- [ ] Bankkonto für Auszahlungen hinterlegt
- [ ] Agreements für In-App Purchase akzeptiert
- [ ] App für Release bereit

---

## Nächste Schritte

Nach iOS Konfiguration:
1. **Android konfigurieren** (siehe `PAYMENT_SETUP_Android.md`)
2. **Flutter App testen** mit `flutter run`
3. **Premium Page Update** - Nutze neue ProductIds Klasse
