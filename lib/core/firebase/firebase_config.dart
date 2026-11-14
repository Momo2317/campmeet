import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camp_meet/firebase_options.dart';

/// Firebase configuration and initialization
class FirebaseConfig {
  static const String projectId = 'campmeet-5094b';
  static const String storageBucket = 'campmeet-5094b.firebasestorage.app';

  /// German university domains that auto-verify on signup
  static const Set<String> germanUniversityDomains = {
    // Technical Universities
    'tum.de', // Technical University of Munich
    'kit.edu', // Karlsruhe Institute of Technology
    'rwth-aachen.de', // RWTH Aachen
    'tu-berlin.de', // TU Berlin
    'tu-dortmund.de', // TU Dortmund
    'tu-braunschweig.de', // TU Braunschweig
    'tu-ilmenau.de', // TU Ilmenau
    'tu-chemnitz.de', // Chemnitz University of Technology
    'uni-hannover.de', // University of Hannover
    'uni-kl.de', // TU Kaiserslautern

    // Research Universities
    'lmu.de', // Ludwig Maximilian University Munich
    'uni-heidelberg.de', // University of Heidelberg
    'uni-bonn.de', // University of Bonn
    'uni-cologne.de', // University of Cologne
    'uni-freiburg.de', // University of Freiburg
    'uni-tuebingen.de', // University of Tübingen
    'uni-goettingen.de', // University of Göttingen
    'uni-marburg.de', // University of Marburg
    'uni-mainz.de', // University of Mainz
    'uni-mannheim.de', // University of Mannheim
    'uni-hamburg.de', // University of Hamburg
    'uni-frankfurt.de', // University of Frankfurt
    'uni-leipzig.de', // University of Leipzig
    'uni-greifswald.de', // University of Greifswald
    'uni-potsdam.de', // University of Potsdam
    'hu-berlin.de', // Humboldt University Berlin
    'fu-berlin.de', // Free University Berlin
    'uni-wuppertal.de', // University of Wuppertal
    'uni-jena.de', // University of Jena
    'uni-muenster.de', // University of Münster
    'uni-duesseldorf.de', // University of Düsseldorf
  };

  /// Initialize Firebase with platform-specific configuration
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Enable offline persistence for Firestore
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );

      // Use Firestore emulator in development (if FIRESTORE_EMULATOR_HOST is set)
      // This is configured via environment variables when running `firebase emulators:start`
    } catch (e) {
      throw Exception('Failed to initialize Firebase: $e');
    }
  }

  /// Check if an email domain is a verified German university
  static bool isGermanUniversityDomain(String email) {
    if (!email.contains('@')) return false;

    final domain = email.split('@').last.toLowerCase();
    return germanUniversityDomains.contains(domain);
  }

  /// Get the university name from email domain
  static String? getUniversityFromDomain(String email) {
    if (!email.contains('@')) return null;

    final domain = email.split('@').last.toLowerCase();
    return _universityNameMap[domain];
  }

  /// Map of domain to university name
  static const Map<String, String> _universityNameMap = {
    'tum.de': 'Technical University of Munich',
    'kit.edu': 'Karlsruhe Institute of Technology',
    'rwth-aachen.de': 'RWTH Aachen University',
    'tu-berlin.de': 'TU Berlin',
    'tu-dortmund.de': 'TU Dortmund',
    'tu-braunschweig.de': 'TU Braunschweig',
    'tu-ilmenau.de': 'TU Ilmenau',
    'tu-chemnitz.de': 'Chemnitz University of Technology',
    'uni-hannover.de': 'University of Hannover',
    'uni-kl.de': 'TU Kaiserslautern',
    'lmu.de': 'Ludwig Maximilian University Munich',
    'uni-heidelberg.de': 'University of Heidelberg',
    'uni-bonn.de': 'University of Bonn',
    'uni-cologne.de': 'University of Cologne',
    'uni-freiburg.de': 'University of Freiburg',
    'uni-tuebingen.de': 'University of Tübingen',
    'uni-goettingen.de': 'University of Göttingen',
    'uni-marburg.de': 'University of Marburg',
    'uni-mainz.de': 'University of Mainz',
    'uni-mannheim.de': 'University of Mannheim',
    'uni-hamburg.de': 'University of Hamburg',
    'uni-frankfurt.de': 'University of Frankfurt',
    'uni-leipzig.de': 'University of Leipzig',
    'uni-greifswald.de': 'University of Greifswald',
    'uni-potsdam.de': 'University of Potsdam',
    'hu-berlin.de': 'Humboldt University Berlin',
    'fu-berlin.de': 'Free University Berlin',
    'uni-wuppertal.de': 'University of Wuppertal',
    'uni-jena.de': 'University of Jena',
    'uni-muenster.de': 'University of Münster',
    'uni-duesseldorf.de': 'University of Düsseldorf',
  };
}
