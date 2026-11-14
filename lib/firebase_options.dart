// Firebase-Konfiguration für Campus Match (Projekt: campmeet-5094b)
// Die Werte stammen aus `firebase apps:sdkconfig`. Bei neuen Apps neu erzeugen.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'Firebase ist für diese Plattform nicht konfiguriert.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA5tThtUNiqRINj0jW9i73b68nNpJ8_YaI',
    appId: '1:687616497073:web:a0e0e9f1f1a463fd191990',
    messagingSenderId: '687616497073',
    projectId: 'campmeet-5094b',
    authDomain: 'campmeet-5094b.firebaseapp.com',
    storageBucket: 'campmeet-5094b.firebasestorage.app',
    measurementId: 'G-1V2Q2ED924',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCuSpvjxYX0_rZ_MuyfjibIk3X-VrTHX-Q',
    appId: '1:687616497073:android:b1b98937293e35be191990',
    messagingSenderId: '687616497073',
    projectId: 'campmeet-5094b',
    storageBucket: 'campmeet-5094b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDo6h9elres6xkloveM7038CUZRchlWfOI',
    appId: '1:687616497073:ios:e4d400b1f3022d3c191990',
    messagingSenderId: '687616497073',
    projectId: 'campmeet-5094b',
    storageBucket: 'campmeet-5094b.firebasestorage.app',
    iosBundleId: 'com.campmeet.app',
  );
}
