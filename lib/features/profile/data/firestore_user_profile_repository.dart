import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camp_meet/features/profile/data/user_profile_model.dart';

/// Firestore-based user profile repository with local cache
class FirestoreUserProfileRepository {
  static final _instance = FirestoreUserProfileRepository._();

  factory FirestoreUserProfileRepository() => _instance;

  FirestoreUserProfileRepository._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _cacheKey = 'cached_user_profile';

  /// Get user profile from Firestore, with fallback to cache
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      // Try to get from Firestore first
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) {
        // Try to get from cache if Firestore fails
        return _getCachedProfile();
      }

      final profileData = doc.data();
      if (profileData == null) return null;

      // Merge Firestore data with local profile if it exists
      final cachedProfile = await _getCachedProfile();
      if (cachedProfile != null) {
        // Firestore is source of truth for verification fields
        final mergedData = cachedProfile.toMap();
        mergedData['isVerified'] = profileData['isVerified'] ?? false;
        mergedData['verificationMethod'] = profileData['verificationMethod'];
        mergedData['verificationDate'] = profileData['verificationDate'];
        mergedData['verificationRequestId'] =
            profileData['verificationRequestId'];

        final profile = UserProfile.fromMap(mergedData);
        // Cache the merged profile
        await _cacheProfile(profile);
        return profile;
      }

      // Convert Firestore data to UserProfile
      final profile = UserProfile.fromMap(profileData);
      await _cacheProfile(profile);
      return profile;
    } catch (e) {
      // Fallback to cache on error
      return _getCachedProfile();
    }
  }

  /// Update user profile in Firestore
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(profile.id).update(
            profile.toMap(),
          );
      // Update cache
      await _cacheProfile(profile);
    } catch (e) {
      throw Exception('Profil aktualisieren fehlgeschlagen: $e');
    }
  }

  /// Create new user profile in Firestore
  Future<void> createUserProfile(UserProfile profile) async {
    try {
      await _firestore.collection('users').doc(profile.id).set(
            profile.toMap(),
          );
      // Cache new profile
      await _cacheProfile(profile);
    } catch (e) {
      throw Exception('Profil erstellen fehlgeschlagen: $e');
    }
  }

  /// Get user profile stream (real-time updates)
  Stream<UserProfile?> getUserProfileStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;

      final profileData = doc.data();
      if (profileData == null) return null;

      final profile = UserProfile.fromMap(profileData);
      // Cache the profile for offline access
      _cacheProfile(profile);
      return profile;
    });
  }

  /// Update only verification fields (admin action)
  Future<void> updateVerificationStatus(
    String userId, {
    required bool isVerified,
    String? verificationMethod,
    DateTime? verificationDate,
    String? verificationRequestId,
  }) async {
    try {
      final updates = <String, dynamic>{
        'isVerified': isVerified,
        if (verificationMethod != null)
          'verificationMethod': verificationMethod,
        if (verificationDate != null)
          'verificationDate': Timestamp.fromDate(verificationDate),
        'verificationRequestId': verificationRequestId,
      };

      await _firestore.collection('users').doc(userId).update(updates);

      // Update cache
      final cachedProfile = await _getCachedProfile();
      if (cachedProfile != null) {
        final updated = cachedProfile.copyWith(
          isVerified: isVerified,
          verificationMethod: verificationMethod,
          verificationDate: verificationDate,
          verificationRequestId: verificationRequestId,
        );
        await _cacheProfile(updated);
      }
    } catch (e) {
      throw Exception('Verifizierungsstatus aktualisieren fehlgeschlagen: $e');
    }
  }

  /// Cache profile locally for offline access
  Future<void> _cacheProfile(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, profile.toJson());
    } catch (e) {
      // Caching failure is not critical
      print('⚠️ Fehler beim Cachen des Profils: $e');
    }
  }

  /// Get cached profile
  Future<UserProfile?> _getCachedProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedJson = prefs.getString(_cacheKey);
      if (cachedJson == null) return null;

      return UserProfile.fromJson(cachedJson);
    } catch (e) {
      return null;
    }
  }

  /// Clear cache (for logout)
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (e) {
      print('⚠️ Fehler beim Löschen des Caches: $e');
    }
  }
}
