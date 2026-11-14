# Android Payment Setup - Google Play Console

## Schritt 1: Google Play Console Vorbereitung

1. Öffne https://play.google.com/console
2. Wähle deine "CampMeet" App
3. Gehe zu "Setup" → "App integrity" - überprüfe Status
4. Gehe zu "Monetize" → "In-app products"

---

## Schritt 2: Zahlungsmethode & Bankkonto

1. Gehe zu "Setup" → "Payment methods"
2. Füge Bankkonto hinzu (für Auszahlungen)
3. Akzeptiere Vereinbarungen unter "Policies"

---

## Schritt 3: In-App Produkte erstellen

### 3.1 Subscriptions

**Premium Monthly (3.99€)**
1. Klicke "Create app" → "Subscription"
2. Product ID: `campmeet.premium.monthly`
3. Default language: English
4. Name: `Premium Monthly`
5. Description: `Unlimited likes, no ads, exclusive features - 1 month`
6. Billing period: Monthly
7. Price: 3,99 EUR (Europa), 3.99 USD (USA)
8. Save & aktiviere

**Premium Annual (29.99€)**
1. Wiederhole für Annual
2. Product ID: `campmeet.premium.annual`
3. Billing period: Yearly
4. Price: 29,99 EUR / 29.99 USD
5. Intro-Preis optional (z.B. 7 Tage kostenlos)

### 3.2 Consumables (Boosts & Super Likes)

**Boost 1x**
1. "Create app" → "In-app product"
2. Product ID: `campmeet.boost.1`
3. Name: `1 Boost`
4. Price: 0,99 EUR

**Boost 5x**
- Product ID: `campmeet.boost.5`
- Price: 3,99 EUR

**Boost 10x**
- Product ID: `campmeet.boost.10`
- Price: 6,99 EUR

**Super Like 5x**
- Product ID: `campmeet.superlike.5`
- Price: 2,99 EUR

**Super Like 20x**
- Product ID: `campmeet.superlike.20`
- Price: 9,99 EUR

---

## Schritt 4: Android Gradle Konfiguration

### 4.1 android/build.gradle

```gradle
buildscript {
    ext {
        kotlin_version = '1.9.0'
    }
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath 'com.android.tools.build:gradle:8.0.0'
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}
```

### 4.2 android/app/build.gradle

```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        applicationId "com.yourcompany.campmeet"
        minSdkVersion 21
        targetSdkVersion 34
        versionCode 1
        versionName "1.0.0"
    }

    dependencies {
        // Google Play Billing Library (bereits von in_app_purchase eingebunden)
        implementation 'com.android.billingclient:billing:7.0.0'
    }
}
```

---

## Schritt 5: Android Manifest

### 5.1 AndroidManifest.xml (android/app/src/main)

Stelle sicher, dass folgende Permissions vorhanden sind:

```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

Die `in_app_purchase` Package sollte diese automatisch hinzufügen.

---

## Schritt 6: Testen

### 6.1 Test-Accounts erstellen
1. Google Play Console → "Testers"
2. Gehe zu "Internal testing" oder "Closed testing"
3. Erstelle Liste von Test-Emails
4. Diese Accounts können kostenlos kaufen

### 6.2 APK bauen & deployen
```bash
flutter build apk --release
```

### 6.3 Zu Google Play Console hochladen
1. Gehe zu "Internal testing"
2. Lade neue APK hoch
3. Lade dir mit Test-Email herunter
4. Teste Käufe

### 6.4 Lokal am Simulator testen
```bash
flutter run --debug
```

Die `in_app_purchase` Package bietet Mock-Funktionalität für Simulator.

---

## Schritt 7: Billing Library Integration Details

Die `in_app_purchase` Package verwaltet die Google Play Billing Library automatisch.

Falls manuelle Konfiguration nötig:

**android/app/build.gradle:**
```gradle
dependencies {
    implementation 'com.android.billingclient:billing:7.0.0'
}
```

---

## Troubleshooting Android

| Problem | Lösung |
|---------|--------|
| "Billing not available" | Google Play Services Update erzwingen |
| "Product not found" | Product ID prüfen, App Release warten (kann 24h dauern) |
| Test-Kauf funktioniert nicht | Test-User zum Testing-Programm hinzufügen |
| APK nicht installierbar | `applicationId` muss mit Play Console übereinstimmen |

---

## Checkliste Android

- [ ] Alle 7 Produkte in Google Play Console erstellt
- [ ] Test-Account erstellt
- [ ] android/app/build.gradle aktualisiert (targetSdkVersion 34+)
- [ ] BILLING Permission in AndroidManifest.xml
- [ ] Internal Testing Build hochgeladen
- [ ] Mit Test-Account getestet
- [ ] Google Play Billing Library kompatibel

---

## Nächste Schritte

1. iOS Setup prüfen (PAYMENT_SETUP_iOS.md)
2. Flutter App im Release-Modus testen
3. Premium-UI aktualisieren (premium_page.dart)
