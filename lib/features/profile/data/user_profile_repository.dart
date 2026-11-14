import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:camp_meet/core/services/firebase_auth_service.dart';
import 'package:camp_meet/features/profile/data/user_profile_model.dart';

const String _kUserProfileKey = 'campmeet_user_profile';
const String _kIsLoggedInKey = 'campmeet_is_logged_in';

/// Notifier für den aktuellen Login-Status
final authSessionProvider = NotifierProvider<AuthSessionNotifier, bool>(() {
  return AuthSessionNotifier();
});

class AuthSessionNotifier extends Notifier<bool> {
  SharedPreferences? _prefs;

  @override
  bool build() {
    _init();
    return false;
  }

  Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
    state = _prefs?.getBool(_kIsLoggedInKey) ?? false;
  }

  Future<void> setLoggedIn(bool loggedIn) async {
    state = loggedIn;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setBool(_kIsLoggedInKey, loggedIn);
  }
}

/// Notifier für das aktuelle Profil des Nutzers
final userProfileProvider =
    NotifierProvider<UserProfileNotifier, UserProfile?>(() {
  return UserProfileNotifier();
});

class UserProfileNotifier extends Notifier<UserProfile?> {
  SharedPreferences? _prefs;

  @override
  UserProfile? build() {
    _loadProfile();
    return null;
  }

  Future<void> _loadProfile() async {
    _prefs ??= await SharedPreferences.getInstance();
    final jsonStr = _prefs?.getString(_kUserProfileKey);
    if (jsonStr != null && jsonStr.isNotEmpty) {
      try {
        state = UserProfile.fromJson(jsonStr);
        return;
      } catch (_) {}
    }
    // Falls noch nichts gespeichert ist, Default-Profil laden
    state = UserProfile.defaultProfile();
  }

  /// Speichert ein neues oder bearbeitetes Profil ab
  Future<void> saveProfile(UserProfile profile) async {
    state = profile;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(_kUserProfileKey, profile.toJson());
    await _prefs?.setBool(_kIsLoggedInKey, true);
    // Auch den Session-Provider informieren
    ref.read(authSessionProvider.notifier).setLoggedIn(true);
  }

  /// Aktualisiert Felder des aktuellen Profils
  Future<void> updateProfile({
    String? name,
    String? email,
    int? age,
    String? university,
    String? major,
    int? semester,
    String? bio,
    String? avatarUrl,
    List<String>? images,
    List<String>? interests,
    int? height,
    String? relationshipType,
    String? zodiac,
    String? orientation,
    String? gender,
    List<String>? languages,
    Map<String, String>? lifestyle,
    Map<String, String>? prompts,
    String? mode,
  }) async {
    final current = state ?? UserProfile.defaultProfile();
    final updated = current.copyWith(
      name: name,
      email: email,
      age: age,
      university: university,
      major: major,
      semester: semester,
      bio: bio,
      avatarUrl: avatarUrl,
      images: images,
      interests: interests,
      height: height,
      relationshipType: relationshipType,
      zodiac: zodiac,
      orientation: orientation,
      gender: gender,
      languages: languages,
      lifestyle: lifestyle,
      prompts: prompts,
      mode: mode,
    );
    await saveProfile(updated);
  }

  /// Schreibt Super Likes / Boosts gut (negative Werte werden nicht abgezogen).
  Future<void> addCredits({int superLikes = 0, int boosts = 0}) async {
    if (state == null) await _loadProfile();
    final current = state ?? UserProfile.defaultProfile();
    await saveProfile(current.copyWith(
      superLikes: current.superLikes + superLikes.clamp(0, 1 << 30),
      boosts: current.boosts + boosts.clamp(0, 1 << 30),
    ));
  }

  /// Zieht einen Super Like ab. Gibt false zurück, wenn keiner mehr da ist.
  Future<bool> consumeSuperLike() async {
    final current = state;
    if (current == null || current.superLikes <= 0) return false;
    await saveProfile(current.copyWith(superLikes: current.superLikes - 1));
    return true;
  }

  /// Gleicht den Verifizierungsstatus mit Firebase ab und übernimmt ihn ins Profil
  Future<void> refreshVerification() async {
    if (!hasFirebaseAccount) return;
    final verified = await FirebaseAuthService().syncVerification();
    final current = state;
    if (current == null || current.isVerified == verified) return;
    final updated = current.copyWith(isVerified: verified);
    state = updated;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(_kUserProfileKey, updated.toJson());
  }

  /// Meldet den Benutzer ab
  Future<void> logout() async {
    try {
      if (hasFirebaseAccount) await FirebaseAuthService().signOut();
    } catch (_) {}
    state = null;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setBool(_kIsLoggedInKey, false);
    ref.read(authSessionProvider.notifier).setLoggedIn(false);
  }

  /// Löscht das Profil vollständig (Account löschen)
  Future<void> deleteAccount() async {
    state = null;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(_kUserProfileKey);
    await _prefs?.setBool(_kIsLoggedInKey, false);
    ref.read(authSessionProvider.notifier).setLoggedIn(false);
  }
}

/// Gibt es ein angemeldetes Firebase-Konto? (false, wenn Firebase fehlt)
bool get hasFirebaseAccount {
  try {
    return FirebaseAuthService().isAuthenticated;
  } catch (_) {
    return false;
  }
}

/// Eingeschränkter Zugang: angemeldet, aber (noch) nicht verifiziert.
/// Solche Konten (z. B. Google ohne Uni-Mail) sehen nur "WG & Zimmer".
final restrictedAccessProvider = Provider<bool>((ref) {
  if (!ref.watch(authSessionProvider)) return false;
  final profile = ref.watch(userProfileProvider);
  if (profile?.isVerified == true) return false;
  return hasFirebaseAccount;
});
