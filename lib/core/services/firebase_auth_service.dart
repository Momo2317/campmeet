import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:camp_meet/core/firebase/firebase_config.dart';
import 'package:flutter/foundation.dart';

/// Exception types for authentication errors
class AuthException implements Exception {
  final String message;
  final String? code;

  AuthException(this.message, {this.code});

  @override
  String toString() => message;
}

/// Firebase Authentication Service with email verification
class FirebaseAuthService {
  static final _instance = FirebaseAuthService._();

  factory FirebaseAuthService() => _instance;

  FirebaseAuthService._();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current authenticated user
  User? get currentUser => _firebaseAuth.currentUser;

  /// Get user ID
  String? get currentUserId => _firebaseAuth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isAuthenticated => _firebaseAuth.currentUser != null;

  /// Sign up with email and password.
  /// Neue Konten sind IMMER unverifiziert. Die Uni-Mail gilt erst nach dem
  /// Klick auf den Bestätigungslink (siehe [syncVerification]).
  /// Returns the created user's UID
  Future<String> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.toLowerCase(),
        password: password,
      );

      final user = userCredential.user;
      if (user == null) {
        throw AuthException('Benutzer konnte nicht erstellt werden');
      }

      await _createUserDocument(user.uid, email.toLowerCase());

      // Besitz der Mail-Adresse bestätigen lassen
      try {
        await user.sendEmailVerification();
      } on FirebaseAuthException catch (e) {
        debugPrint('⚠️ Bestätigungsmail nicht gesendet: ${e.code}');
      }

      return user.uid;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e), code: e.code);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Registrierung fehlgeschlagen: $e');
    }
  }

  Future<void> _createUserDocument(String uid, String email) {
    return _firestore.collection('users').doc(uid).set({
      'id': uid,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'isVerified': false,
      'verificationMethod': null,
      'verificationDate': null,
      'verificationRequestId': null,
      'isPlatinum': false,
      'isBanned': false,
      'isFlagged': false,
    });
  }

  /// Mit Google anmelden (neue Konten starten unverifiziert).
  /// Wirft [AuthException] mit code 'canceled', wenn der Nutzer abbricht.
  Future<String> signInWithGoogle() async {
    try {
      final credential =
          await _firebaseAuth.signInWithProvider(GoogleAuthProvider());
      final user = credential.user;
      if (user == null) {
        throw AuthException('Google-Anmeldung fehlgeschlagen');
      }
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _createUserDocument(user.uid, (user.email ?? '').toLowerCase());
      }
      return user.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'canceled' ||
          e.code == 'web-context-canceled' ||
          e.code == 'popup-closed-by-user') {
        throw AuthException('Anmeldung abgebrochen', code: 'canceled');
      }
      throw AuthException(_mapFirebaseAuthError(e), code: e.code);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Google-Anmeldung fehlgeschlagen: $e');
    }
  }

  /// Gleicht den Verifizierungsstatus mit Firebase ab:
  /// - Uni-Mail bestätigt (Link geklickt / Google-Mail bestätigt) -> verifiziert
  /// - sonst Stand aus Firestore (z. B. Studentenausweis vom Support freigegeben)
  /// Liefert true, wenn das Konto verifiziert ist.
  Future<bool> syncVerification() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return false;
    try {
      await user.reload();
      final fresh = _firebaseAuth.currentUser ?? user;
      final ref = _firestore.collection('users').doc(fresh.uid);
      final snap = await ref.get();
      final verified = snap.data()?['isVerified'] == true;
      if (verified) return true;

      final email = (fresh.email ?? '').toLowerCase();
      if (fresh.emailVerified &&
          FirebaseConfig.isGermanUniversityDomain(email)) {
        await ref.update({
          'isVerified': true,
          'verificationMethod': 'email',
          'verificationDate': FieldValue.serverTimestamp(),
        });
        return true;
      }
    } catch (e) {
      debugPrint('⚠️ Verifizierungsabgleich fehlgeschlagen: $e');
    }
    return false;
  }

  /// Bestätigungsmail erneut senden
  Future<void> resendVerificationEmail() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    try {
      await user.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e), code: e.code);
    }
  }

  /// Sign in with email and password
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.toLowerCase(),
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e), code: e.code);
    } catch (e) {
      throw AuthException('Anmeldung fehlgeschlagen: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw AuthException('Abmeldung fehlgeschlagen: $e');
    }
  }

  /// Check if email is a German university email
  bool isUniversityEmail(String email) {
    return FirebaseConfig.isGermanUniversityDomain(email);
  }

  /// Get university name from email domain
  String? getUniversityFromEmail(String email) {
    return FirebaseConfig.getUniversityFromDomain(email);
  }

  /// Verify user (called by admin when approving student ID)
  Future<void> verifyUser({
    required String userId,
    required String method, // 'email' or 'student_id'
    String? approvedBy,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isVerified': true,
        'verificationMethod': method,
        'verificationDate': FieldValue.serverTimestamp(),
      });

      await _logVerificationAction(
        userId: userId,
        action: 'verified',
        method: method,
        details: 'User verified via $method',
        approvedBy: approvedBy ?? 'admin',
      );
    } catch (e) {
      throw AuthException('Verifizierung fehlgeschlagen: $e');
    }
  }

  /// Reject verification request
  Future<void> rejectVerification({
    required String userId,
    required String rejectionReason,
    required String rejectedBy,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'verificationRequestId': null,
      });

      await _logVerificationAction(
        userId: userId,
        action: 'rejected',
        method: 'student_id',
        details: 'Verification rejected: $rejectionReason',
        approvedBy: rejectedBy,
      );
    } catch (e) {
      throw AuthException('Ablehnung fehlgeschlagen: $e');
    }
  }

  /// Get user verification status
  Future<Map<String, dynamic>?> getUserVerificationStatus(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (!doc.exists) return null;

      final data = doc.data();
      return {
        'isVerified': data?['isVerified'] ?? false,
        'verificationMethod': data?['verificationMethod'],
        'verificationDate': data?['verificationDate'],
        'verificationRequestId': data?['verificationRequestId'],
      };
    } catch (e) {
      throw AuthException(
          'Verifizierungsstatus konnte nicht abgerufen werden: $e');
    }
  }

  /// Log verification action in audit trail
  Future<void> _logVerificationAction({
    required String userId,
    required String action,
    required String method,
    required String details,
    required String approvedBy,
  }) async {
    try {
      await _firestore.collection('verificationAuditLog').add({
        'userId': userId,
        'action': action, // 'auto_verified', 'verified', 'rejected'
        'method': method,
        'details': details,
        'approvedBy': approvedBy,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('⚠️ Fehler beim Protokollieren der Verifizierung: $e');
    }
  }

  /// Map Firebase Auth errors to German messages
  String _mapFirebaseAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Benutzer nicht gefunden';
      case 'wrong-password':
        return 'Falsches Passwort';
      case 'email-already-in-use':
        return 'Email wird bereits verwendet';
      case 'invalid-email':
        return 'Ungültige Email-Adresse';
      case 'weak-password':
        return 'Passwort ist zu schwach';
      case 'operation-not-allowed':
        return 'Operation nicht erlaubt';
      case 'user-disabled':
        return 'Benutzer wurde deaktiviert';
      default:
        return 'Authentifizierungsfehler: ${e.message}';
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email.toLowerCase());
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseAuthError(e), code: e.code);
    } catch (e) {
      throw AuthException('Passwort zurücksetzen fehlgeschlagen: $e');
    }
  }

  /// Get auth state changes stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
